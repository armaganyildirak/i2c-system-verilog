module i2c_master (
    input wire clk,              // System clock
    input wire rst_n,            // Active-low reset
    input wire enable,           // Start transaction
    input wire [6:0] slave_addr, // 7-bit slave address
    input wire [7:0] data,       // Data byte to send
    output reg scl,              // I2C clock line
    inout wire sda,              // I2C data line (bidirectional)
    output reg busy,             // Indicates transaction in progress
    output reg ack_received,     // Indicates ACK/NACK from slave
    output wire sda_oe_debug,    // Debug: SDA output enable
    output wire sda_in_debug,    // Debug: SDA input value
    output wire [1:0] scl_div_debug, // Debug: SCL divider
    output wire [2:0] state_debug // Debug: FSM state
);

    // FSM states
    localparam IDLE      = 3'd0,
               START     = 3'd1,
               ADDR      = 3'd2,
               RW        = 3'd3,
               DATA      = 3'd4,
               ACK       = 3'd5,
               STOP      = 3'd6;

    reg [2:0] state, next_state;
    reg [3:0] bit_count;         // Counts bits for address and data
    reg [7:0] shift_reg;         // Shift register for address and data
    reg sda_out;                 // SDA output value
    reg sda_oe;                  // SDA output enable (1 = drive, 0 = high-Z)
    wire sda_in;                 // SDA input value
    reg [1:0] ack_counter;       // Counter to extend ACK state
    reg [1:0] scl_div;           // SCL clock divider
    reg ack_sampled;             // Flag to indicate ACK has been sampled

    // Tri-state buffer for SDA
    assign sda = sda_oe ? sda_out : 1'bz;
    
    // Read SDA input value with proper handling of high-Z
    // In simulation, we need to handle the case where SDA might be floating
    assign sda_in = (sda === 1'bz) ? 1'b1 : sda;  // Default to 1 (pull-up) when floating
    
    assign sda_oe_debug = sda_oe;      // Debug output
    assign sda_in_debug = sda_in;      // Debug output
    assign scl_div_debug = scl_div;    // Debug output
    assign state_debug = state;        // Debug output

    // Clock divider for SCL
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            scl_div <= 2'b0;
        else if (state != IDLE)
            scl_div <= scl_div + 1;
    end

    // SCL generation: toggle when not in IDLE, START, or STOP
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            scl <= 1'b1;
        else if (state == IDLE || state == START)
            scl <= 1'b1;
        else if (state == STOP) begin
            if (scl_div == 2'b01 || scl_div == 2'b10)
                scl <= 1'b1;
            else
                scl <= scl;
        end
        else if (scl_div == 2'b11)
            scl <= ~scl;
    end

    // FSM state register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    // ACK counter and sampling - separated for clarity
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ack_counter <= 2'b0;
            ack_sampled <= 1'b0;
            ack_received <= 1'b0;
        end
        else begin
            if (state == ACK) begin
                // Sample ACK when SCL is high during ACK state
                if (scl && !ack_sampled) begin
                    ack_received <= (sda_in == 1'b0); // ACK = 0, NACK = 1
                    ack_sampled <= 1'b1;
                //  $display("Time=%0t: ACK sampled! sda=%b, sda_in=%b, ack_received set to %b", 
                //          $time, sda, sda_in, (sda_in == 1'b0));
                end
                
                // Increment counter on falling SCL edge
                if (scl_div == 2'b11 && !scl) begin
                    ack_counter <= ack_counter + 1;
                end
            end
            else begin
                if (state == IDLE) begin
                    ack_counter <= 2'b0;
                    ack_sampled <= 1'b0;
                    ack_received <= 1'b0;
                end
            end
        end
    end

    // FSM next state and output logic
    always @(*) begin
        next_state = state;
        sda_out = 1'b1;
        sda_oe = 1'b1;
        busy = 1'b1;

        case (state)
            IDLE: begin
                busy = 1'b0;
                sda_oe = 1'b1;
                sda_out = 1'b1;
                if (enable)
                    next_state = START;
            end
            START: begin
                sda_out = 1'b0; // Pull SDA low while SCL is high
                if (scl_div == 2'b11)
                    next_state = ADDR;
            end
            ADDR: begin
                sda_out = shift_reg[7]; // Send address MSB first
                if (scl_div == 2'b11 && !scl) begin
                    if (bit_count == 4'd6)
                        next_state = RW;
                end
            end
            RW: begin
                sda_out = 1'b0; // Write bit (0)
                if (scl_div == 2'b11 && !scl)
                    next_state = DATA;
            end
            DATA: begin
                sda_out = shift_reg[7]; // Send data MSB first
                if (scl_div == 2'b11 && !scl) begin
                    if (bit_count == 4'd7)
                        next_state = ACK;
                end
            end
            ACK: begin
                sda_oe = 1'b0; // Release SDA for slave ACK
                
                if (scl_div == 2'b11 && !scl && ack_counter >= 2'd1)
                    next_state = STOP;
            end
            STOP: begin
                // First keep SDA low while SCL is low
                if (scl_div == 2'b00 || scl_div == 2'b01) begin
                    sda_out = 1'b0;
                    sda_oe = 1'b1;
                end
                // Then release SDA (STOP condition: SDA rising while SCL high)
                else begin
                    sda_out = 1'b1;
                    sda_oe = 1'b1;
                    if (scl_div == 2'b11)
                        next_state = IDLE;
                end
            end
            default: next_state = IDLE;
        endcase
    end

    // Shift register and bit counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= 8'b0;
            bit_count <= 4'b0;
        end
        else if (state == IDLE && enable) begin
            shift_reg <= {slave_addr, 1'b0}; // Load address + RW bit
            bit_count <= 4'b0;
        end
        else if (state == ADDR && scl_div == 2'b11 && !scl) begin
            shift_reg <= {shift_reg[6:0], 1'b0}; // Shift left
            bit_count <= bit_count + 1;
        end
        else if (state == RW && scl_div == 2'b11 && !scl) begin
            shift_reg <= data; // Load data
            bit_count <= 4'b0;
        end
        else if (state == DATA && scl_div == 2'b11 && !scl) begin
            shift_reg <= {shift_reg[6:0], 1'b0}; // Shift left
            bit_count <= bit_count + 1;
        end
    end

endmodule
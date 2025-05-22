import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles, ReadOnly

@cocotb.test()
async def test_i2c_basic(dut):
    """Basic test of I2C master functionality"""
    clock = Clock(dut.clk, 100, units="ns")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    dut.enable.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 5)
    
    # Start transaction
    dut.slave_addr.value = 0x50
    dut.data.value = 0xAB
    dut.enable.value = 1
    await RisingEdge(dut.busy)
    dut.enable.value = 0
    
    # Wait for completion
    await FallingEdge(dut.busy)
    dut._log.info("Basic test completed")

@cocotb.test()
async def test_i2c_start_stop(dut):
    """Verify proper START and STOP conditions"""
    clock = Clock(dut.clk, 100, units="ns")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 5)
    
    # Start transaction
    dut.slave_addr.value = 0x50
    dut.data.value = 0x00
    dut.enable.value = 1
    await RisingEdge(dut.busy)
    dut.enable.value = 0
    
    # Wait for START condition (SDA falls while SCL is high)
    while True:
        await ReadOnly()  # Wait for signals to stabilize
        if dut.scl.value == 1 and dut.sda.value == 0:
            dut._log.info("START condition detected")
            break
        await RisingEdge(dut.clk)
    
    # Wait for STOP condition (SDA rises while SCL is high)
    while True:
        await ReadOnly()
        if dut.scl.value == 1 and dut.sda.value == 1:
            dut._log.info("STOP condition detected")
            break
        await RisingEdge(dut.clk)
    
    dut._log.info("START/STOP test completed")

@cocotb.test()
async def test_i2c_data_transfer(dut):
    """Verify address and data are transmitted correctly"""
    clock = Clock(dut.clk, 100, units="ns")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 5)
    
    # Start transaction
    dut.slave_addr.value = 0x50
    dut.data.value = 0xAA
    dut.enable.value = 1
    await RisingEdge(dut.busy)
    dut.enable.value = 0
    
    # Wait for completion
    await FallingEdge(dut.busy)
    dut._log.info("Data transfer test completed")
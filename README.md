# I2C Master Controller with Testbench

A Verilog implementation of an I2C master controller with testbench using Cocotb.

## Features

- Standard I2C protocol implementation (100kHz mode)
- 7-bit slave addressing
- Single-byte write transactions
- Proper START/STOP condition generation
- ACK/NACK detection from slave
- Configurable clock divider
- Debug signals for state monitoring

## Files

- **i2c_master.v** - I2C master controller implementation
- **test_i2c.py** - Cocotb test script
- **Makefile** - Build and simulation script

## Requirements

- Icarus Verilog
- Python
- Cocotb

## Usage

1. Run the test:

```bash
make
```
2. Clean generated files:

```bash
make clean
```

## Test Cases

The testbench verifies:

1. Basic transaction flow
2. Proper START/STOP conditions
3. Address and data transmission
4. ACK/NACK handling

```
     0.00ns INFO     cocotb                             Running on Icarus Verilog version 12.0 (stable)
     0.00ns INFO     cocotb                             Running tests with cocotb v1.9.2 from /usr/lib/python3.13/site-packages/cocotb
     0.00ns INFO     cocotb                             Seeding Python random module with 1747871382
     0.00ns INFO     cocotb.regression                  Found test test_i2c.test_i2c_basic
     0.00ns INFO     cocotb.regression                  Found test test_i2c.test_i2c_start_stop
     0.00ns INFO     cocotb.regression                  Found test test_i2c.test_i2c_data_transfer
     0.00ns INFO     cocotb.regression                  running test_i2c_basic (1/3)
                                                          Basic test of I2C master functionality
   900.00ns INFO     cocotb.i2c_master                  Basic test completed
   900.00ns INFO     cocotb.regression                  test_i2c_basic passed
   900.00ns INFO     cocotb.regression                  running test_i2c_start_stop (2/3)
                                                          Verify proper START and STOP conditions
 16800.00ns INFO     cocotb.i2c_master                  START condition detected
 17200.00ns INFO     cocotb.i2c_master                  STOP condition detected
 17200.00ns INFO     cocotb.i2c_master                  START/STOP test completed
 17200.00ns INFO     cocotb.regression                  test_i2c_start_stop passed
 17200.00ns INFO     cocotb.regression                  running test_i2c_data_transfer (3/3)
                                                          Verify address and data are transmitted correctly
 18200.00ns INFO     cocotb.i2c_master                  Data transfer test completed
 18200.00ns INFO     cocotb.regression                  test_i2c_data_transfer passed
 18200.00ns INFO     cocotb.regression                  *****************************************************************************************
                                                        ** TEST                             STATUS  SIM TIME (ns)  REAL TIME (s)  RATIO (ns/s) **
                                                        *****************************************************************************************
                                                        ** test_i2c.test_i2c_basic           PASS         900.00           0.00     628413.15  **
                                                        ** test_i2c.test_i2c_start_stop      PASS       16300.00           0.01    1729456.87  **
                                                        ** test_i2c.test_i2c_data_transfer   PASS        1000.00           0.00    1119676.51  **
                                                        *****************************************************************************************
                                                        ** TESTS=3 PASS=3 FAIL=0 SKIP=0                 18200.00           0.25      74200.48  **
                                                        *****************************************************************************************
```
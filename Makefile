TOPLEVEL = i2c_master
MODULE = test_i2c
VERILOG_SOURCES = i2c_master.v

include $(shell cocotb-config --makefiles)/Makefile.sim

clean::
	rm -rf results.xml __pycache__ sim_build
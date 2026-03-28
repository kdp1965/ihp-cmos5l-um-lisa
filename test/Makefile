# Makefile
# See https://docs.cocotb.org/en/stable/quickstart.html for more info

# defaults
SIM ?= icarus
FST ?= -fst # Use more efficient FST format
TOPLEVEL_LANG ?= verilog
SRC = $(PWD)/../src

ifneq ($(GATES),yes)

# this is the only part you should need to modify:
VERILOG_SOURCES += $(SRC)/tt_um_lisa.v $(SRC)/RAM32.v
VERILOG_SOURCES += $(SRC)/lisa_core.v $(SRC)/lisa_dbg.v $(SRC)/lisa_periph.v
VERILOG_SOURCES += $(SRC)/lisa_rx8n.v $(SRC)/lisa_tx8n.v $(SRC)/lisa_qqspi.v
VERILOG_SOURCES += $(SRC)/lisa_qspi_controller.v $(SRC)/lisa_io_mux.v
VERILOG_SOURCES += $(SRC)/lisa_div.v $(SRC)/data_cache.v $(SRC)/inst_cache.v
VERILOG_SOURCES += $(SRC)/debug_ctrl.v $(SRC)/debug_autobaud.v
VERILOG_SOURCES += $(SRC)/debug_brg.v $(SRC)/debug_regs.v $(SRC)/lisa_uart.v $(SRC)/fops.v
VERILOG_SOURCES += $(SRC)/lisa_i2c.v $(SRC)/i2c_master_byte_ctrl.v $(SRC)/i2c_master_bit_ctrl.v
VERILOG_SOURCES += $(PWD)/psram.v $(PWD)/spiflash.v
COMPILE_ARGS    += -I$(SRC)

else

# Gate level simulation:
SIM_BUILD				= sim_build/gl
COMPILE_ARGS    += -DGL_TEST
COMPILE_ARGS    += -DFUNCTIONAL
COMPILE_ARGS    += -DUSE_POWER_PINS
COMPILE_ARGS    += -DSIM
COMPILE_ARGS    += -DUNIT_DELAY=\#1
VERILOG_SOURCES += $(PDK_ROOT)/ihp-sg13cmos5l/libs.ref/sg13cmos5l_io/verilog/sg13cmos5l_io.v
VERILOG_SOURCES += $(PDK_ROOT)/ihp-sg13cmos5l/libs.ref/sg13cmos5l_stdcell/verilog/sg13cmos5l_stdcell.v

# this gets copied in by the GDS action workflow
VERILOG_SOURCES += $(PWD)/gate_level_netlist.v
VERILOG_SOURCES += $(SRC)/lisa_rx8n.v $(SRC)/lisa_tx8n.v $(SRC)/debug_brg.v
VERILOG_SOURCES += $(PWD)/psram.v $(PWD)/spiflash.v

endif

# Allow sharing configuration between design and testbench via `include`:
COMPILE_ARGS 		+= -I$(SRC)

# Include the testbench sources:
VERILOG_SOURCES += $(PWD)/tb.v
TOPLEVEL = tb

# List test modules to run, separated by commas and without the .py suffix:
COCOTB_TEST_MODULES = test

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim

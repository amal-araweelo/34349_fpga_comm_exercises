VLIB = vlib
VLOG = vlog
VSIM = vsim

VLOG_OPT = -timescale=1ns/1ps
ALTERA_LIB = C:/altera_lite/25.1std/quartus/eda/sim_lib/altera_mf.v
WORK = work

RTL = rtl
TB = tb


RTL_FILES = \
	$(RTL)/submodules/bin2gray.sv \
	$(RTL)/submodules/gray2bin.sv \
	$(RTL)/submodules/fifo_ram.v \
	$(RTL)/async_fifo.sv

TB_FILES = \
	$(TB)/src/async_fifo_pkg.sv \
	$(TB)/src/async_fifo_if.sv \
	$(TB)/tb_async_fifo.sv

TOP = tb_async_fifo
TOP_OLD = async_fifo_test

all: compile

compile:
	$(VLIB) $(WORK)
	$(VLOG) $(VLOG_OPT) $(ALTERA_LIB)
	$(VLOG) $(VLOG_OPT) $(RTL_FILES) $(TB_FILES)

sim: compile
	$(VSIM) $(TOP)

wave: compile
	$(VSIM) -do "add wave -r *; run -all" $(TOP)

batch: compile
	$(VSIM) -c $(TOP) -do "run -all; quit"

clean:
	@if exist work rmdir /s /q work
	@if exist transcript del /q transcript
	@if exist vsim.wlf del /q vsim.wlf
	@if exist wlf* del /q wlf*
	@if exist modelsim.ini del /q modelsim.ini

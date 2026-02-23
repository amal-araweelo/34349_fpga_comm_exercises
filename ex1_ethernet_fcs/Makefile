VLIB = vlib
VLOG = vlog
VSIM = vsim

VLOG_OPT = -timescale=1ns/1ps

WORK = work

RTL = rtl
TB = tb

SV_FILES = \
	$(TB)/src/fcs_if.sv \
	$(TB)/src/fcs_pkg.sv \
	$(RTL)/fcs_serial_check.sv \
	$(TB)/tb_fcs_serial_check.sv \
	$(RTL)/fcs_parallel_check.sv \
	$(TB)/tb_fcs_parallel_check.sv


TOP = tb_fcs_serial_check

all: compile

compile:
	$(VLIB) $(WORK)
	$(VLOG) $(VLOG_OPT) $(SV_FILES)

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

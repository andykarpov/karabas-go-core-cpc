# Amstrad CPC core: the ISE flow (XST, ngdbuild, map, par, bitgen) for the Karabas boards.
#   make measure-xst      Ф0: the whole upstream emu module on stubs (measure/), -iobuf NO
#   make measure-report   its utilization from the .syr

SHELL = /bin/bash
ISE_SETTINGS ?= /opt/Xilinx/14.7/ISE_DS/settings64.sh
XIL = . $(ISE_SETTINGS) >/dev/null &&

prj_src = $(shell sed -n 's/^[a-z]* work "\(.*\)"/\1/p' $(1) 2>/dev/null)

.PHONY: measure-xst measure-report clean

cpc_measure.ngc: measure/cpc_measure.prj measure/cpc_measure.xst $(call prj_src,measure/cpc_measure.prj)
	mkdir -p xst/projnav.tmp
	$(XIL) xst -intstyle ise -ifn measure/cpc_measure.xst -ofn cpc_measure.syr

measure-xst: cpc_measure.ngc
measure-report:
	@sed -n '/Device utilization summary/,/Partition Resource Summary/p' cpc_measure.syr | grep -E "Number of (Slice Registers|Slice LUTs|Block RAM/FIFO|DSP48|BUFG)"
	@grep -E "Minimum period|Maximum Frequency|latch" cpc_measure.syr | sort -u | head

clean:
	rm -rf xst _xmsgs xlnx_auto_0_xdb
	rm -f cpc_measure.ngc cpc_measure.ngr cpc_measure.syr cpc_measure.lso cpc_measure_xst.xrpt

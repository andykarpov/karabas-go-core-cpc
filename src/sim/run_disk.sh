#!/bin/bash
# u765 (rtl/sv2v) + cpc_sd_sdc against a model of the file mounter (tb_disk.v), verilator --timing.
#   sim/run_disk.sh [file.dsk]      (default: rtl/amstrad/u765/test.dsk of upstream)
set -e
cd "$(dirname "$0")/.."
B=sim/build/disk
mkdir -p $B
SRC="sim/tb_disk.v rtl/sv2v/u765.v rtl/sv2v/u765_dpram.v rtl/karabas/cpc_sd_sdc.v"
if [ ! -x $B/Vtb_disk ] || [ -n "$(find $SRC sim/run_disk.sh -newer $B/Vtb_disk 2>/dev/null)" ]; then
	verilator --binary --timing -O2 -Wno-fatal -Wno-lint -Wno-style --top-module tb_disk -Mdir $B $SRC \
		> $B/verilator.log 2>&1 || { grep -E '%Error' $B/verilator.log | head; exit 1; }
fi
$B/Vtb_disk ${1:++dsk=$1} | grep -v -E '^(sector found|reload)'

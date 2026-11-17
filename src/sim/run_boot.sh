#!/bin/bash
# Builds the verilator model of cpc_core (rtl/sv2v = what XST builds, the VHDL through ghdl, the
# port case fixed by fixcase.py, tb_cpc.v) and runs sim_cpc with the given arguments (see
# sim_cpc.cpp). The build goes to src/sim/build. Run from anywhere.
#   sim/run_boot.sh --ms 1500 --ppm sim/build/f --every 25
set -e
cd "$(dirname "$0")"
SIM=$(pwd)
SRC=$(cd .. && pwd)
B=$SIM/build
mkdir -p $B/v
VHD=$(sed -n 's/^vhdl work "\(.*\)"/\1/p' $SRC/cpc.prj | sed "s#^#$SRC/#")
VLOG=$(sed -n 's/^verilog work "\(.*\)"/\1/p' $SRC/cpc.prj | sed "s#^#$SRC/#")
VLOG="$VLOG $SRC/../modules/rtl/mem/kg_fifo.v"
if [ ! -f $B/vhdl_ghdl.v ] || [ -n "$(find $VHD vhdl2v.sh -newer $B/vhdl_ghdl.v 2>/dev/null)" ]; then
	./vhdl2v.sh $B > $B/ghdl.log 2>&1 || { grep -v -i warning $B/ghdl.log | tail -30; exit 1; }
fi
BIN=$B/obj/Vtb_cpc
[ "$(cat $B/obj/threads 2>/dev/null)" != "$VTHREADS" ] && rm -f $BIN
if [ ! -x $BIN ] || [ -n "$(find $B/vhdl_ghdl.v $VLOG tb_cpc.v sim_cpc.cpp fixcase.py run_boot.sh -newer $BIN 2>/dev/null)" ]; then
	rm -f $B/v/*.v
	python3 -I fixcase.py $B/vhdl_ghdl.v $B/v $VLOG
	verilator -O3 ${VTHREADS:+--threads $VTHREADS} -Wno-fatal -Wno-lint -Wno-style -Wno-BLKANDNBLK -Wno-MULTIDRIVEN \
		-Wno-COMBDLY -Wno-UNOPTFLAT --no-timing +1364-2005ext+v --top-module tb_cpc \
		-Mdir $B/obj --cc $B/v/*.v tb_cpc.v --exe $SIM/sim_cpc.cpp -CFLAGS "-std=c++17 -O2" \
		-o Vtb_cpc > $B/verilator.log 2>&1 || { grep -E '%Error' $B/verilator.log | head -30; exit 1; }
	make -s -j8 -C $B/obj -f Vtb_cpc.mk > $B/make.log 2>&1 || { tail -30 $B/make.log; exit 1; }
	echo "$VTHREADS" > $B/obj/threads
fi
cd $SRC
exec $BIN "$@"

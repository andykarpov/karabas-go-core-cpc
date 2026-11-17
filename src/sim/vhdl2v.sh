#!/bin/bash
# The VHDL entities that the Verilog of the core instantiates (T80pa, tzxplayer, CPC_Dandanator,
# z80ctc_top), each as a Verilog netlist for verilator: ghdl --synth with the generics of their
# instances. Run from anywhere.
#   sim/vhdl2v.sh <out dir>   -> <out dir>/vhdl_ghdl.v
set -eu
OUT=$(mkdir -p "${1:?output dir}" && cd "$1" && pwd)
SRC=$(cd "$(dirname "$0")/.." && pwd)
cd "$SRC"
VHD=$(sed -n 's/^vhdl work "\(.*\)"/\1/p' cpc.prj)
mkdir -p "$OUT/ghdl"
G="--std=08 -fsynopsys -frelaxed --workdir=$OUT/ghdl"
rm -f "$OUT"/ghdl/work-obj08.cf
# a copy of the VHDL: instance labels renamed where ghdl makes a net name of label_port that is
# also a signal (T80: label alu, port Q -> alu_q = the signal ALU_Q)
mkdir -p "$OUT/vhd"
for f in $VHD; do
	sed -e 's/^\tmcode : T80_MCode/\tu_mcode : T80_MCode/' -e 's/^\talu : T80_ALU/\tu_alu : T80_ALU/' \
		-e 's/^\tRegs : T80_Reg/\tu_regs : T80_Reg/' "$f" > "$OUT/vhd/$(basename "$f")"
	ghdl -a $G "$OUT/vhd/$(basename "$f")"
done
{
	ghdl --synth $G --out=verilog T80pa
	ghdl --synth $G --out=verilog -gNORMAL_PILOT_LEN=2000 -gNORMAL_SYNC1_LEN=855 -gNORMAL_SYNC2_LEN=855 \
		-gNORMAL_ZERO_LEN=855 -gNORMAL_ONE_LEN=1710 -gHEADER_PILOT_PULSES=4095 -gNORMAL_PILOT_PULSES=4095 tzxplayer
	ghdl --synth $G --out=verilog CPC_Dandanator
	ghdl --synth $G --out=verilog z80ctc_top
} > "$OUT/vhdl_ghdl.v"
wc -l "$OUT/vhdl_ghdl.v"

#!/bin/bash
# Converts the upstream RTL (SystemVerilog and the SV-flavoured .v of the renaudguerin
# Amstrad_MiSTer fork, tag v2026.11.07) to Verilog-2001 for XST with sv2v (/opt/sv2v/sv2v):
# one file per module in the output dir. VHDL (T80, tzxplayer, Dandanator, PlayCity CTC) goes to
# XST as is.
#   tools/sv2v.sh measure   Ф0: the whole MiSTer emu module on the stubs of measure/stubs.sv
#                           -> measure/sv2v/, measure/cpc_measure.prj (make measure-xst)
#   tools/sv2v.sh measure-classic   the same with KG_CLASSIC (Plus model forced Off, no CPR,
#                           no SSM / snapshot save) -> measure/sv2v_classic/ (make measure-classic-xst)
set -e
cd "$(dirname "$0")/.."
SV2V=${SV2V:-/opt/sv2v/sv2v}
A=rtl/amstrad
RTL=$(find $A -name '*.v' -o -name '*.sv' | grep -v -E '_test\.|_tb\.|sna_lifecycle_top' | sort)
VHDL="$A/T80/T80_Pack.vhd $A/T80/T80_Reg.vhd $A/T80/T80_ALU.vhd $A/T80/T80_MCode.vhd $A/T80/T80.vhd $A/T80/T80pa.vhd
 $A/tzxplayer.vhd $A/dandanator/cpc_dandanator.vhd
 $A/playcity/Z80CTC/ctc_counter.vhd $A/playcity/Z80CTC/ctc_controler.vhd $A/playcity/Z80CTC/z80ctc_top.vhd"
case "$1" in
measure|measure-classic)
	OUT=measure/sv2v; DEF=; PRJ=measure/cpc_measure.prj
	[ "$1" = measure-classic ] && { OUT=measure/sv2v_classic; DEF=-DKG_CLASSIC; PRJ=measure/cpc_measure_classic.prj; }
	rm -rf $OUT && mkdir $OUT
	$SV2V $DEF -I ../upstream -I measure --top=emu measure/Amstrad.sv measure/stubs.sv $RTL -w $OUT 2>&1 \
		| grep -v -E '^\s*$|Warning: Number literal|^ *[0-9]* \||^\s*\|' || true
	{ for f in $VHDL; do echo "vhdl work \"$f\""; done
	  for f in $OUT/*.v; do echo "verilog work \"$f\""; done; } > $PRJ
	ls $OUT | wc -l ;;
*) echo "usage: $0 measure|measure-classic"; exit 1 ;;
esac

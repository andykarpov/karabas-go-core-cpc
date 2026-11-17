#!/bin/bash
# Converts the upstream RTL (SystemVerilog and the SV-flavoured .v of the renaudguerin
# Amstrad_MiSTer fork, tag v2026.11.07) to Verilog-2001 for XST with sv2v (/opt/sv2v/sv2v):
# one file per module in the output dir. VHDL (T80, tzxplayer, Dandanator, PlayCity CTC) goes to
# XST as is.
#   tools/sv2v.sh measure   Ф0: the whole MiSTer emu module on the stubs of measure/stubs.sv
#                           -> measure/sv2v/, measure/cpc_measure.prj (make measure-xst)
#   tools/sv2v.sh measure-classic   the same with KG_CLASSIC (Plus model forced Off, no CPR,
#                           no SSM / snapshot save) -> measure/sv2v_classic/ (make measure-classic-xst)
#   tools/sv2v.sh core      the core: cpc_core + the upstream it uses -> rtl/sv2v/,
#                           cpc.prj (the source list of the core, the board .prj files add the tops)
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
core)
	# the core: cpc_core (the board independent part); the tops add cpc_clocks, cpc_video_out
	OUT=rtl/sv2v
	rm -rf $OUT && mkdir $OUT
	$SV2V -DKG_CLASSIC -I ../upstream --top=cpc_core rtl/karabas/cpc_emu.sv rtl/karabas/cpc_mister_stubs.sv \
		rtl/karabas/cpc_core.v rtl/karabas/cpc_sram.v ../modules/rtl/mem/kg_fifo.v \
		$RTL -w $OUT 2>&1 | grep -v -E '^\s*$|Warning: Number literal|^ *[0-9]* \||^\s*\|' || true
	rm -f $OUT/kg_fifo.v   # the boards take it from modules/
	{ for f in $VHDL; do echo "vhdl work \"$f\""; done
	  for f in $OUT/*.v; do echo "verilog work \"$f\""; done; } > cpc.prj
	# the boards: the modules of karabas-go-modules (tools/board_modules.prj), the core, the clocks, the top
	for b in minig; do   # Go and Mini: Ф3 (tools/mktops.py)
		{ cat tools/board_modules.prj; cat cpc.prj
		  echo 'verilog work "rtl/karabas/cpc_clocks.v"'
	  echo 'verilog work "rtl/karabas/cpc_video_out.v"'
		  echo "verilog work \"rtl/karabas_${b}_top.v\""; } > karabas_$b.prj
	done
	ls $OUT | wc -l ;;
*) echo "usage: $0 measure|measure-classic|core"; exit 1 ;;
esac

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

An Amstrad CPC core for the Karabas Go, Mini and Mini G boards (Xilinx Spartan-6 XC6SLX25, ISE 14.7, XST): a port of the [renaudguerin/Amstrad_MiSTer](https://github.com/renaudguerin/Amstrad_MiSTer) fork (tag v2026.11.07) of the MiSTer Amstrad core. Classic CPC 464 / 664 / 6128 first, CPC Plus / GX4000 later (it does not fit as is). Docs, in Russian: `docs/PLAN.md` (research, decisions, phases, the Ф0 fit numbers). Follow the phases; record a changed decision in PLAN.md.

User decisions (2026-11-17): base = the renaudguerin fork; the system ROMs are built into the `.kg`; measurements first, then the classic machine. Public repo, core id `cpc`.

## Layout

- `src/rtl/amstrad/`: the upstream `rtl/` (Quartus pll / .qip left out), changes marked `// karabas:` / `-- karabas:`.
- `upstream/`: `Amstrad.sv`, the MiSTer `sys/` files it uses, README, CREDITS, `roms/boot.rom` (reference, not built).
- `src/measure/`: the Ф0 fit check. `Amstrad.sv` = a patched copy of the upstream top (`KG_CLASSIC` forces Plus off), `stubs.sv` = stand-ins for `hps_io`, `pll`, `ltc2308_tape`, `video_mixer`, `video_freak`, `altddio_out`. `src/tools/sv2v.sh measure|measure-classic` -> `measure/sv2v*/` + `.prj` (generated, in git); `make measure-xst` / `make measure-classic-xst` (about 20 min each) and `make measure-report` / `measure-classic-report`.

## Rules of the core

The rules of the other karabas-go cores apply: standard video timing with syncs always present, `FT_CLK_OUT` about 8 MHz on Mini / Mini G, Go `FDC_*` outputs 0 when unused, Mini / Mini G drive T3 (`FLASH_CS_N`) = 0, OSD switch index = item position unless `"index"`, an OSD value shows 10 characters at most, FL slots 0..7 only, Verilog-2001 for XST (`sv2v` for SV), imported code marked `karabas:`.

- sv2v pitfalls seen here: SV keywords used as names (`do`), local `reg x = 0` inside `always` (re-initialised every clock: move it to module scope), `inout reg`, writes into 2-D arrays (XST tristates, Xst:2037).
- Keep the CRTC Compendium credit lines in the CRTC sources and the visible credits (`upstream/CREDITS.md`).
- **Ask the user before every check on the board** (and the HDMI capture). Ask before a firmware flash.
- One branch per phase of `docs/PLAN.md`, one PR at its end.
- Heavy builds: Mini G only while working on one feature, all boards for a release; map with cost table 2 first.

## Memory

The Claude Code memory of this repo is shared with all karabas-go repos: `~/.claude/projects/<this project>/memory` is a symlink to `../karabas-go-notes` (private repo `andykarpov/karabas-go-notes`). Its `MEMORY.md` is split by repo; commit and push it after every memory change.

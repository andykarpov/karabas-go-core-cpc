# Amstrad CPC core for Karabas Go / Mini / Mini G

[Русская версия](README.ru.md)

Amstrad CPC 6128, 664 and 464 for the Karabas Go board family (Xilinx Spartan-6 XC6SLX25). A port of the [renaudguerin Amstrad_MiSTer fork](https://github.com/renaudguerin/Amstrad_MiSTer) of the [MiSTer Amstrad core](https://github.com/MiSTer-devel/Amstrad_MiSTer). Only the classic models: the CPC Plus / GX4000 part of the fork does not fit the FPGA as it is.

| Board | Core file | Video | Sound |
|---|---|---|---|
| Karabas Go | `cpc.kg` | VGA | I2S DAC (PCM5102) |
| Karabas Mini | `cpc.kg` | HDMI | HDMI, analog output (sigma-delta) |
| Karabas Mini G | `cpc.kg` | HDMI | HDMI, I2S DAC |

The core file is in `src/`. The system ROMs of the three models (OS, BASIC, AMSDOS) are built into it. Disk, tape, snapshot and ROM images are not included: put your own on the SD card in `/cpc`.

Status: checked on Mini G. The Go and Mini builds have not been run on a board yet.

## Features

- **Machines:** CPC 6128 (128K), 664 and 464 (64K): Z80 at 4 MHz, Gate Array, CRTC type 1 or 0, AY-3-8912.
- **Disks:** two drives (A and B), `.dsk` images (standard and extended), read and write: changes go back to the image on the SD card.
- **Tape:** `.cdt` images, loaded at the speed of a real tape.
- **Snapshots:** `.sna` images (load only).
- **Expansion ROMs:** `.eXX` files as on MiSTer: `.e00` .. `.e1f` put the ROM in that upper ROM slot (the number is hex); `.ez0` replaces the lower ROM and BASIC (for example the 464 firmware on a 6128); `.ezz` as on MiSTer.
- **Video:** the 50 Hz picture of the CPC with its border, line-doubled to 1024 x 624 at 50 Hz (31.25 kHz); colour or a green / amber / cyan / white monitor.
- **Sound:** the AY in stereo (ABC) and the tape sound.
- **Controllers:** the keyboard, two joysticks (USB pads). The mouse is connected as in the MiSTer core but has not been tried.

Not done yet: Multiface II, PlayCity, CPC Plus / GX4000.

## Getting started

1. Copy `cpc.kg` (one file for Go, Mini and Mini G) to the root of the SD card.
2. Put your images in `/cpc` on the SD card.
3. Choose Amstrad CPC in the core menu. The CPC 6128 starts in BASIC. Open the OSD (**Menu+Esc**), choose a disk in Disk A (**Menu+F1**), then type `cat` and `run"name`.

"Menu" is the Windows key of the keyboard.

Tape on a 6128 or 664: type `|tape`, then `run""` and press a key; choose the image in Tape (**Menu+F3**). A 464 reads the tape without `|tape`.

## OSD menu

| Item | Values | Hotkey |
|---|---|---|
| Disk A, Disk B | `.dsk` image | Menu+F1, Menu+F2 |
| Tape | `.cdt` image | Menu+F3 |
| Snapshot | `.sna` image | Menu+F4 |
| ROM | `.e00` .. `.e1f`, `.ez0`, `.ezz` | Menu+F5 |
| Model | CPC 6128 / 664 / 464 | Menu+M |
| CRTC | Type 1 / Type 0 | |
| Display | Colour GA / Colour ASIC / Green / Amber / Cyan / White | Menu+D |
| Reset | resets the machine | F12 |

The settings and the mounted disks are remembered. A change of Model restarts the machine.

## Keyboard

The keyboard is positional: a PC key types what the CPC key in the same place types, not what is printed on the PC key. Some symbols on a US keyboard:

| CPC | PC key |
|---|---|
| `"` | Shift+2 |
| `\|` | Shift+[ |
| `:` | ; |
| `=` | Shift+- |
| `(` | Shift+8 |
| `)` | Shift+9 |

Reset of the machine: F12.

## Building

Clone with `--recursive` (the `modules` submodule). ISE 14.7: `cd src && make` for all boards or `make minig` for one. The Mini and Go tops (and the timing part of their ucf) are made from the Mini G top by `src/tools/mktops.py`; the converted sources (`src/rtl/sv2v`) by `src/tools/sv2v.sh core`; the wrapper of the MiSTer `emu` by `src/tools/make_cpc_emu.py`. The Verilator checks: `src/sim/run_boot.sh` (the machine to the BASIC prompt), `src/sim/run_disk.sh` (the disk controller against a model of the file mounter). The plan and the design notes are in [docs/PLAN.md](docs/PLAN.md) (Russian).

## Licence

The Karabas parts are GPL v3 ([LICENSE](LICENSE)); the MiSTer core and the fork are GPL (see `upstream/CREDITS.md` for the authors). The CPC system ROMs are copyright Amstrad and Locomotive Software; Amstrad allows their distribution with emulators provided the copyright notices are kept. Imported files keep the licence headers of their authors.

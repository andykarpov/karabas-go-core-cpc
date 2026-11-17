#!/usr/bin/env python3
"""A test snapshot (.sna, version 1, 64K) for the Snapshot item of the core: a small program at &4000
fills the screen (&C000..&FFFF) with pen 1 (bright yellow in mode 1) and then stripes of pens 2 / 3 in
the middle, and waits (DI, JR $). Border and pen 0 blue, the standard CRTC of a CPC, both ROMs off.
After a load the picture shows at once: a yellow screen with a cyan / red band, a blue border.
  tools/mksna.py test.sna
"""
import sys

PROG_AT = 0x4000

# LD HL,&C000 ; LD DE,&C001 ; LD BC,&3FFF ; LD (HL),&F0 ; LDIR
# LD HL,&C000+80*8*... the band: lines 80..119 of the 8-row character lines = character rows 10..14:
# for each of the 8 raster lines r: &C000 + r*&800 + row*80, 5 rows * 80 bytes = 400 bytes of &0F/&FF
prog = bytearray()
prog += bytes([0x21, 0x00, 0xC0, 0x11, 0x01, 0xC0, 0x01, 0xFF, 0x3F, 0x36, 0xF0, 0xED, 0xB0])
for r in range(8):
    start = 0xC000 + r * 0x800 + 10 * 80
    val = 0x0F if r < 4 else 0xFF          # pen 2 (cyan) / pen 3 (red) in mode 1
    # LD HL,start ; LD DE,start+1 ; LD BC,399 ; LD (HL),val ; LDIR
    prog += bytes([0x21, start & 0xFF, start >> 8, 0x11, (start + 1) & 0xFF, (start + 1) >> 8,
                   0x01, 399 & 0xFF, 399 >> 8, 0x36, val, 0xED, 0xB0])
prog += bytes([0x18, 0xFE])  # JR $


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    h = bytearray(0x100)
    h[0:8] = b"MV - SNA"
    h[0x10] = 1                                   # version
    h[0x1B] = 0                                   # IFF0: interrupts off
    h[0x1C] = 0
    h[0x21:0x23] = (0xBFF0).to_bytes(2, "little") # SP
    h[0x23:0x25] = PROG_AT.to_bytes(2, "little")  # PC
    h[0x25] = 1                                   # IM 1
    h[0x2E] = 0                                   # GA selected pen
    pal = [0x04, 0x0A, 0x13, 0x0C] + [0x04] * 12 + [0x04]   # pens 0..15, border (hardware colours)
    h[0x2F:0x2F + 17] = bytes(pal)
    h[0x40] = 0x01 | 0x04 | 0x08                  # GA: mode 1, lower and upper ROM off
    h[0x41] = 0                                   # RAM configuration
    h[0x42] = 0
    crtc = [63, 40, 46, 0x8E, 38, 0, 25, 30, 0, 7, 0, 0, 0x30, 0, 0, 0, 0, 0]
    h[0x43:0x43 + 18] = bytes(crtc)
    h[0x55] = 0                                   # upper ROM select
    h[0x59] = 0x82                                # PPI control (as the firmware: A out, B in, C out)
    h[0x6B:0x6D] = (64).to_bytes(2, "little")     # memory dump size, K
    mem = bytearray(0x10000)
    mem[PROG_AT:PROG_AT + len(prog)] = prog
    with open(sys.argv[1], "wb") as f:
        f.write(h + mem)


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""A blank formatted CPC disk image (the standard "MV - CPCEMU" .dsk): AMSDOS DATA format, 40 tracks,
1 side, 9 sectors of 512 bytes (IDs C1..C9), all bytes E5 (an empty directory). For the disk checks of
the core: SAVE / CAT / LOAD on the CPC write and read it.
  tools/mkdsk.py blank.dsk
"""
import struct
import sys

TRACKS, SECTORS, SIZE = 40, 9, 512


def track(t):
    info = bytearray(256)
    info[0:12] = b"Track-Info\r\n"
    info[0x10] = t           # track
    info[0x11] = 0           # side
    info[0x14] = 2           # sector size code: 512
    info[0x15] = SECTORS
    info[0x16] = 0x4E        # gap 3
    info[0x17] = 0xE5        # filler
    for s in range(SECTORS):
        info[0x18 + 8 * s:0x18 + 8 * s + 4] = bytes((t, 0, 0xC1 + s, 2))  # C H R N, ST1 ST2 0
    return bytes(info) + b"\xE5" * (SECTORS * SIZE)


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    head = bytearray(256)
    head[0:34] = b"MV - CPCEMU Disk-File\r\nDisk-Info\r\n"
    head[0x22:0x22 + 14] = b"karabas mkdsk "
    head[0x30] = TRACKS
    head[0x31] = 1
    struct.pack_into("<H", head, 0x32, 256 + SECTORS * SIZE)
    with open(sys.argv[1], "wb") as f:
        f.write(head)
        for t in range(TRACKS):
            f.write(track(t))


if __name__ == "__main__":
    main()

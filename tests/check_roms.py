#!/usr/bin/env python3
"""Validate a Metal Slug X ROM directory against MAME's mslugx set.

Usage: python tests/check_roms.py <rom-dir>

Checks presence, size and SHA-1 of every file the player loads, then two
structural facts that the port depends on:

  * the fixed program bank is word-swapped and carries "NEO-GEO" at $100
    (the check the BIOS itself makes);
  * each 1 MB bank of 250-p2.ep1 ends with its own bank number, which is what
    the game reads back through the $2FFFF0 bank-select port.

Nothing is written. Exit code 0 = usable set.
"""
import hashlib
import os
import sys

FILES = {
    "250-p1.p1":  (0x100000, "4c19f2e9824e606178ac1c9d4b0516fbaa625035"),
    "250-p2.ep1": (0x400000, "18aaa7a3ba8da99f78c430e9be69ccde04bc04d9"),
    "250-c1.c1":  (0x800000, "c3e8a8ccdac0f8bddc4c3413277626532405fae2"),
    "250-c2.c2":  (0x800000, "554f600a3aa09c16c13c625299b087a79d0d15c5"),
    "250-c3.c3":  (0x800000, "c56646c62387bc1439d46610258c755beb8d7dd8"),
    "250-c4.c4":  (0x800000, "31be8ea2498001f68ce4b06b8b90acbf2dcab6af"),
    "250-c5.c5":  (0x800000, "d41069856df990a1a99d39fb263c8303389d5475"),
    "250-c6.c6":  (0x800000, "39be66287696829d243fb71b3fb8b7dc2bc3298f"),
    "250-s1.s1":  (0x20000,  "2cc392ecde5d5afb28ddbaa1030552b48571dcfb"),
    "250-m1.m1":  (0x20000,  "55769bad4860f64ef53a333e0da9e073db483d6a"),
    "250-v1.v1":  (0x400000, "ebfcc67204ff9677cf7972fd5b6b7faabf07280c"),
    "250-v2.v2":  (0x400000, "526c42ca9a388f7435569400e2f132e2724c71ff"),
    "250-v3.v3":  (0x200000, "45979d1edb1fc774a415d9386f98d7cb252a2043"),
    # BIOS, from the neogeo set
    "sp-s2.sp1":  (0x20000,  None),
    "sfix.sfix":  (0x20000,  None),
    "sm1.sm1":    (0x20000,  None),
    "000-lo.lo":  (0x20000,  None),
}


def sha1(path):
    h = hashlib.sha1()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def main(rom_dir):
    if not os.path.isdir(rom_dir):
        print(f"FAIL: {rom_dir} is not a directory")
        return 2
    bad = 0
    for name, (size, want) in FILES.items():
        path = os.path.join(rom_dir, name)
        if not os.path.exists(path):
            print(f"MISSING  {name}")
            bad += 1
            continue
        got_size = os.path.getsize(path)
        got_hash = sha1(path)
        ok = got_size == size and (want is None or got_hash == want)
        print(f"{'ok      ' if ok else 'MISMATCH'} {name:12s} {got_size:9d}  {got_hash}")
        if not ok:
            bad += 1

    p1 = os.path.join(rom_dir, "250-p1.p1")
    if os.path.exists(p1):
        with open(p1, "rb") as f:
            head = bytearray(f.read(0x200))
        for i in range(0, len(head), 2):           # MAME ROM_LOAD16_WORD_SWAP
            head[i], head[i + 1] = head[i + 1], head[i]
        sig = bytes(head[0x100:0x107])
        if sig == b"NEO-GEO":
            print("ok       fixed bank is word-swapped and has NEO-GEO at $100")
        else:
            print(f"MISMATCH fixed bank signature is {sig!r}, expected b'NEO-GEO'")
            bad += 1

    p2 = os.path.join(rom_dir, "250-p2.ep1")
    if os.path.exists(p2):
        with open(p2, "rb") as f:
            data = f.read()

        def swapped(off):
            # MAME loads P ROMs with ROM_LOAD16_WORD_SWAP: the 68k sees the
            # other byte of each 16-bit word.
            return data[off ^ 1]

        for bank in range(len(data) // 0x100000):
            b = swapped(bank * 0x100000 + 0xFFFFF)
            ok = b == bank
            print(f"{'ok      ' if ok else 'MISMATCH'} 250-p2 bank {bank} id byte = {b:02X}")
            if not ok:
                bad += 1

    if bad:
        print(f"\nFAIL: {bad} problem(s)")
        return 1
    print("\nPASS: ROM set is complete and structurally correct")
    return 0


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("usage: python tests/check_roms.py <rom-dir>")
        sys.exit(2)
    sys.exit(main(sys.argv[1]))

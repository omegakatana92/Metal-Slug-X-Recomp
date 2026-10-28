Metal Slug X - native Windows x64 recompilation
===============================================

This is a static recompilation of Metal Slug X's Motorola 68000 program,
built on neogeorecomp. It is not an emulator frontend: the 68000 code runs
as compiled C against a model of the MVS board, with Musashi used only for
code reached through swapped bank windows.

Requirements
------------
* Windows 10/11 x64.
* Your own legally obtained ROMs:
    - the MAME "mslugx" set:
        250-p1.p1   250-p2.ep1
        250-c1.c1   250-c2.c2   250-c3.c3
        250-c4.c4   250-c5.c5   250-c6.c6
        250-s1.s1   250-m1.m1
        250-v1.v1   250-v2.v2   250-v3.v3
    - the MAME "neogeo" system ROM set, for sp-s2.sp1, sfix.sfix,
      sm1.sm1 and 000-lo.lo
  No ROMs or BIOS images are included in this package.

Preparing the ROMs
------------------
Right-click Prepare-ROMs.ps1 and choose "Run with PowerShell" (or run it
from a terminal). It asks for the two zips and extracts them, flat, into the
"roms" folder. Everything stays local; it never downloads anything.

Alternatively, if you already have the files extracted, put them in a folder
named "roms" beside "Metal Slug X.exe".

Running
-------
Double-click "Play Metal Slug X.cmd", or run:

    "Metal Slug X.exe" --rom-path roms

Command line (the standard neogeorecomp set):
    --rom-path DIR   --bios-path DIR   --bios FILE
    --headless       --frames N        --screenshot N:FILE
    --input FILE     --verify          --dump-misses FILE
    --scale N        --fullscreen      --wav FILE   --mute

Controls
--------
    arrows / left stick      move
    Z X C V / A B X Y        Neo Geo A B C D
    5 / Back                 insert coin
    1 / Start                start
    3 / left shoulder        select
    9                        service
    F2                       test switch
    F11                      toggle fullscreen
    Esc                      quit

Status of this build
--------------------
* Boots the real MVS BIOS (sp-s2.sp1), shows the Metal Slug X warning/title,
  accepts coins, starts a game and runs Mission 1 from the owner's dump.
* `--verify` over a 3,200-frame scripted session: 2,105,133 blocks checked,
  0 mismatches.
* Native coverage over a 19,000-frame play session: 90.04% native. Code the
  game runs while the bank window points at banks 1-3 runs in the bundled
  Musashi interpreter (correct, just not native); shorter sessions are 100%.
* Audio: the YM2610 (FM/SSG/ADPCM-A/B) is synthesized by ymfm and converted to
  the device's own format by SDL. On the build machine the device negotiated
  55,555 Hz float with 0 stalls over a 240-frame run.
* Windowed and fullscreen (4:3 pillarboxed) runs exit cleanly.

See the project README for the full numbers and the test log.

License
-------
Original project code: PolyForm Noncommercial 1.0.0 (confirmed by the project
ownerecomp is MIT; Musashi, superzazu/z80 and ymfm
keep their own MIT/BSD-3 licences. See LICENSES\THIRD_PARTY_NOTICES.txt in
this folder for the full notices. No SNK code or ROM data is claimed as
original, and none is distributed.

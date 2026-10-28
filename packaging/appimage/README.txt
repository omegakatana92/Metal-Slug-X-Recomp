Metal Slug X - native static recompilation
==========================================

This AppImage contains the recompiled game and the SDL2 window/audio layer.
It does NOT contain game ROMs or the Neo Geo BIOS: supply your own legally
obtained dump.

Quick start
-----------
1. Put the unzipped ROM files in a folder named "roms" next to the AppImage
   (or in ~/.local/share/mslugx/roms, ~/Emulation/roms/mslugx,
   ~/roms/mslugx, or ~/roms). AppRun finds those automatically.

     mkdir -p roms
     unzip mslugx.zip -d roms
     unzip neogeo.zip -d roms

   The MAME "mslugx" set must contain:
     250-p1.p1 250-p2.ep1 250-c1.c1 .. 250-c6.c6
     250-s1.s1 250-m1.m1 250-v1.v1 250-v2.v2 250-v3.v3
   The "neogeo" BIOS set must contain at least:
     sp-s2.sp1 sfix.sfix sm1.sm1 000-lo.lo
   Metal Slug X is an unencrypted cartridge, so no extra tool is needed.

2. Run the AppImage. It starts in fullscreen with a 4:3 pillarboxed image.

Controls
--------
  Arrows / left stick      move
  Z X C V / pad A B X Y    Neo Geo A B C D
  5 / pad Back             insert coin
  1 / pad Start            start
  3 / pad left shoulder    select
  9                        service
  F2                       test switch
  F11                      toggle fullscreen
  Esc                      quit

Notes
-----
* The MVS BIOS is the real sp-s2.sp1 system ROM; there is no BIOS HLE.
* The game's 68000 code is statically recompiled. Code reached only through
  a swapped bank window runs in the bundled Musashi interpreter; the measured
  share is reported in the project README.
* Audio is synthesized by ymfm from the Z80 sound driver and the V ROMs, then
  resampled to whatever rate the device accepts.

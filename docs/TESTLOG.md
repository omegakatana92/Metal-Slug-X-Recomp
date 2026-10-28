# Test log — Metal Slug X

Every command below was run from the project root. `ROM_DIR` is the owner's
own dump: the MAME `mslugx` and `neogeo` sets extracted flat into `roms-src`.

## Environment

| Item | Value |
|---|---|
| Windows | 10.0.26200, MSVC 19.51.36257 (Visual Studio 18 2026), CMake 4.3.3 |
| Linux | Ubuntu 22.04 on WSL2, gcc 11.4.0, CMake 4.4.4, SDL2 2.0.20 |
| Display | Windows desktop (windowed + fullscreen); Xvfb 1280x800 for the AppImage |
| Toolkit | neogeorecomp v0.2.0 (`af96b2b`) with the generic fixes listed in the README |
| ROM dump | MAME `mslugx` + `neogeo`, unmodified |

## 1. ROM validation

```
python tests/check_roms.py roms-src
```

```
ok       250-p1.p1      1048576  4c19f2e9824e606178ac1c9d4b0516fbaa625035
ok       250-p2.ep1     4194304  18aaa7a3ba8da99f78c430e9be69ccde04bc04d9
ok       250-c1.c1      8388608  c3e8a8ccdac0f8bddc4c3413277626532405fae2
ok       250-c2.c2      8388608  554f600a3aa09c16c13c625299b087a79d0d15c5
ok       250-c3.c3      8388608  c56646c62387bc1439d46610258c755beb8d7dd8
ok       250-c4.c4      8388608  31be8ea2498001f68ce4b06b8b90acbf2dcab6af
ok       250-c5.c5      8388608  d41069856df990a1a99d39fb263c8303389d5475
ok       250-c6.c6      8388608  39be66287696829d243fb71b3fb8b7dc2bc3298f
ok       250-s1.s1       131072  2cc392ecde5d5afb28ddbaa1030552b48571dcfb
ok       250-m1.m1       131072  55769bad4860f64ef53a333e0da9e073db483d6a
ok       250-v1.v1      4194304  ebfcc67204ff9677cf7972fd5b6b7faabf07280c
ok       250-v2.v2      4194304  526c42ca9a388f7435569400e2f132e2724c71ff
ok       250-v3.v3      2097152  45979d1edb1fc774a415d9386f98d7cb252a2043
ok       sp-s2.sp1       131072  4f5ed7105b7128794654ce82b51723e16e389543
ok       sfix.sfix       131072  fd4a618cdcdbf849374f0a50dd8efe9dbab706c3
ok       sm1.sm1         131072  42f9d7ddd6c0931fd64226a60dc73602b2819dcf
ok       000-lo.lo       131072  5992277debadeb64d1c1c64b0a92d9293eaf7e4a
ok       fixed bank is word-swapped and has NEO-GEO at $100
ok       250-p2 bank 0 id byte = 00
ok       250-p2 bank 1 id byte = 01
ok       250-p2 bank 2 id byte = 02
ok       250-p2 bank 3 id byte = 03

PASS: ROM set is complete and structurally correct
```

## 2. Interpreted boot (board model only)

```
metal-slug-x --headless --interp --rom-path ROM_DIR --frames 3000
```

* `[neogeorecomp] mslugx: 58608 recompiled entry points, interpreter only`
* frame 900: MVS BIOS "WARNING / THIS ROM CARTRIDGE IS FOR USE WITH ORIGINAL
  SNK BOARDS ONLY" screen, correct 8x8 fix font and colours.
* frame 1500 (native run): METAL SLUG X title, SNK logo, "PRESS 1P START",
  "CREDIT 1" after the coin script.
* frame 2399 (native run): "MISSION 1 START!" desert bridge, HUD, sprites and
  scrolling all drawn by the recompiled code.

## 3. Native build and boot

```
cmake -S . -B build-windows -G "Visual Studio 18 2026" -A x64 -DMSLUGX_ROM_DIR=DIR
cmake --build build-windows --config Release --parallel
build-windows\Release\Metal Slug X.exe --headless --rom-path DIR --frames 3000 --input tests/coin_start.txt
```

```
[neogeorecomp] mslugx: 59302 recompiled entry points
[exec] native blocks 1797982, native instructions 52336323,
       interpreted instructions 139 (100.00% native), 6 uncovered entry points
```

## 4. CPU verification (`--verify`)

```
Metal Slug X.exe --headless --verify --rom-path DIR --frames 3200 --input tests/play.txt
```

```
[verify] 2105133 blocks checked, 0 mismatches
[exec] native blocks 2105133, native instructions 56493155,
       interpreted instructions 139 (100.00% native), 6 uncovered entry points
```

The same run on the Linux build: `[verify] 2105178 blocks checked, 0
mismatches`. The small difference in block count is the uPD4990A calendar:
the emulated RTC is seeded from the host clock, so two sessions on different
days take slightly different paths through the BIOS date code. Everything
else is deterministic.

Two bugs were found and fixed *by* this check, both generic:

* the bank-window guard tested `(a & 0xFE0000) == 0x200000`, which only covers
  `$200000-$21FFFF`; code at `$220000-$2FFFFF` therefore ran the *bank 0*
  translation while another bank was selected. One real mismatch
  (`$28774C`, `fb59` vs `tst.l ($34,A6)`) exposed it;
* the new protection device's internal ROM read went through the bus and was
  logged as a game access, desynchronising the replay (18,171 false
  mismatches). It now reads the ROM/work RAM directly, as the chip does.

## 5. Native coverage

```
Metal Slug X.exe --headless --rom-path DIR --frames 19000 --input tests/play_long.txt
```

```
[exec] native blocks 13699145, native instructions 302472046,
       interpreted instructions 33472923 (90.04% native), 34 uncovered entry points
```

19000 frames took 75.7 s, i.e. **251 fps, 4.2x real time** (headless, MSVC
Release, on the build machine). The 10% interpreted share is code the game
runs with the bank window pointing at bank 1-3: the v0.2.0 table describes
only the first banked megabyte, so the dispatcher interprets those blocks
instead of executing stale code. A shorter session (`tests/play.txt`, 3200
frames) is 100.00% native.

The `profile` target ran once (`--dump-misses`, 6000 + 19000 frames) and added
691 runtime-only entry points; the table now has 59,302 entries.

## 6. Audio

```
metal-slug-x --headless --rom-path DIR --frames 12001 --input tests/play_long.txt --wav out.wav
python3 tests/check_audio.py out.wav
python3 tests/analyze_audio.py out.wav
```

```
duration 202.77 s, 55555 Hz stereo
peak 32767 (3 samples at full scale), rms 4326, balance 1.008
longest silent run 4 s; runs at 14-17, 21-24, 96-98, 109-110, 135-137,
156-159, 191-193, 201 s
PASS: audio is continuous after boot
```

The gaps line up with the BIOS hand-off, the mission-load transition and
area changes. `NG_AUDIO_TRACE` shows the Z80 driver still taking commands and
switching M1 banks through them (`banks=0B000/0A000/08000/04000` ->
`1B000/1A000/18000/14000`), so these are the game's own silences, not a
stalled driver.

## 7. Windows Release build and launch

* `Metal Slug X.exe` 50.3 MB, Release x64, imports SDL2.dll + the VC runtime.
* Headless: BIOS -> attract -> coin -> title -> Mission 1 (screenshots).
* Windowed (`--scale 2`), 300 frames with the coin script: runs and exits 0.
* Fullscreen (`--fullscreen`, 240 frames): runs and exits 0.
* Audio device on this machine: `55555 Hz, 2 ch, 32-bit` — i.e. SDL accepted
  the rate but changed the format to float and the runtime converted it:
  `[audio-sdl] device 55555 Hz, 2 ch, 32-bit, 1024-sample chunks; source 55555
  Hz stereo`, queue 73-78 ms, max 92 ms, **0 stalls** over 240 frames.
* Package `dist/windows/Metal Slug X-Windows-x64/` runs from its own folder:
  `--headless --rom-path <dump>` boots and renders.

## 8. Steam Deck AppImage

```
bash packaging/appimage/build-appimage.sh DIR
./Metal_Slug_X-SteamDeck-x86_64.AppImage --appimage-extract-and-run --headless ...
```

* Size 23.4 MB, executable bit set, x86-64 ELF, AppImage type 2.
* Headless: boots, `[exec] ... (100.00% native)`, screenshot written.
* Xvfb 1280x800, `--fullscreen`:
  `[window] output 1280x800 dst 107,0 1066x800 fullscreen=1` — 4:3 content,
  1066x800 centred, 107 px pillarbox each side, no stretching.
* X11 capture (`ffmpeg -f x11grab`) shows the METAL SLUG X title screen drawn
  inside those bars.
* `ldd` with `LD_LIBRARY_PATH=usr/lib` (what AppRun sets) resolves
  `libSDL2-2.0.so.0` from `usr/lib/libSDL2-2.0.so.0` inside the AppDir, not
  from the system. The remaining dependencies (libc, libstdc++, libasound,
  libpulse) come from the base system, as AppImage convention expects.

## Not tested

* Physical Steam Deck / SteamOS, Gaming Mode, Steam Input, Deck speakers.
* Physical gamepads (no device attached here).
* Subjective listening on any audio device.
* Full-game completion: the sessions cover attract, coin/start, Mission 1 and
  about 5 minutes of scripted play.

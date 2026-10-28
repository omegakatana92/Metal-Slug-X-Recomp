# Metal Slug X — native static recompilation

A native recompilation of **Metal Slug X — Super Vehicle-001** (SNK, 1999,
MVS/AES, MAME set `mslugx`). The game's Motorola 68000 program is translated
ahead of time into C by [neogeorecomp](https://github.com/sp00nznet/neogeorecomp)
and executed as native x86-64 code against a model of the MVS board. This is
not an emulator frontend: there is no 68000 interpreter in the hot path, only
Musashi as the fallback for code the recompiler did not cover (and as the
`--verify` oracle).

Two deliverables are produced from the same source:

| Target | Artifact |
|---|---|
| Windows 10/11 x64 | `dist/windows/Metal Slug X-Windows-x64/Metal Slug X.exe` |
| Linux x86-64 / Steam Deck | `dist/steamdeck/Metal_Slug_X-SteamDeck-x86_64.AppImage` |

No ROM data or BIOS image is included. You supply your own legally obtained
dump; see [Preparing the ROMs](#preparing-the-roms).

## Current status

| Area | State |
|---|---|
| Build (Windows x64, MSVC) | see [Measured results](#measured-results) |
| Build (Linux x86-64, gcc) | see [Measured results](#measured-results) |
| Boot | real MVS BIOS (`sp-s2.sp1`): memory test, eyecatcher, coin/credit, cart boot |
| Gameplay | title, attract, Mission 1 (see measured results) |
| Native coverage | measured per run; reported by the binary itself |
| `--verify` | measured per run; 0 mismatches required |
| Sound | Z80 driver + YM2610 (FM/SSG/ADPCM-A/B) through ymfm |

Everything in the table above is a *measurement of this source tree*, not a
claim about the game in general. Numbers that were not measured are labelled
as untested.

## Hardware model

Metal Slug X is a plain, unencrypted cartridge; no NEO-SMA, NEO-CMC or
protection latch is involved.

| Region | Files | Layout |
|---|---|---|
| P ROM | `250-p1.p1`, `250-p2.ep1` | 1 MB fixed bank + 4 MB banked (`$200000` window, NEO-ZMC 1 MB banks) |
| C ROM | `250-c1.c1` … `250-c6.c6` | 6 × 8 MB, byte-interleaved to 48 MB of 4-bitplane tiles |
| S ROM | `250-s1.s1` | 128 KB fixed layer (`NG_FIX_BANK_NONE`) |
| M ROM | `250-m1.m1` | 128 KB Z80 sound driver |
| V ROM | `250-v1.v1`, `250-v2.v2`, `250-v3.v3` | 4 + 4 + 2 MB ADPCM-A samples |
| BIOS | `sp-s2.sp1`, `sfix.sfix`, `sm1.sm1`, `000-lo.lo` | real MVS system ROMs, no HLE |

Both P ROM files are byte-swapped per 16-bit word in the MAME set
(`ROM_LOAD16_WORD_SWAP`) and P1 is already the fixed bank, P2 the banked
image, so `src/game.c` loads them at `0x000000` and `0x100000` with `swap = 1`.
The fixed bank carries `NEO-GEO` at `$100`, which is the check in
[docs/COMPATIBILITY.md](docs/COMPATIBILITY.md).

### Cartridge protection

Metal Slug X is built on the **NEO-MVS PROGEOP** board (with KOF '98), which
has an ALTERA EPM7128 at `$2FFFE0-$2FFFEF`. Its boot self-test writes a
command and reads a bit table back out of the cartridge ROM; if the chip does
not answer, the game prints "THIS ROM CARTRIDGE IS FOR USE WITH ORIGINAL SNK
BOARDS ONLY" and parks in a watchdog-kick loop with interrupts masked — which
looks exactly like a hang on the BIOS warning screen.

The runtime now models that device (`NG_PROT_TYPE_BITSTREAM`, documented in
[docs/COMPATIBILITY.md](docs/COMPATIBILITY.md#the-progeop-protection-device)).
It is a board feature rather than a title patch: `src/game.c` supplies only
the table address (`$0DEDD2`) and the work-RAM selector (`$10F00A`) that this
particular cartridge wires up.

### Banked code

The 68k sees only `$200000-$2FFFFF` for the banked image, so the recompiler
translates the fixed bank plus the *first* banked megabyte (bank 0). When the
game points the window at another bank, the dispatcher refuses the stale
native translation and runs that code in Musashi — a stale native block would
execute the wrong bytes. The share of instructions executed natively is printed
at exit as `[exec] ... (NN.NN% native)`; see
[Measured results](#measured-results).

This is a known coverage limit of the v0.2.0 toolkit's single bank window, not
a game-specific hack: the same rule applies to every banked Neo Geo title.

## Preparing the ROMs

The runtime reads *files*, not zips. Put these in a folder named `roms` beside
the executable (or pass `--rom-path DIR`):

```
unzip mslugx.zip -d roms     # MAME "mslugx" set
unzip neogeo.zip -d roms     # MAME "neogeo" BIOS set
```

The packaged Windows build has `Prepare-ROMs.ps1` which does this for you.
The AppImage's `AppRun` looks for `roms` beside the AppImage,
`~/.local/share/mslugx/roms`, `~/Emulation/roms/mslugx`, `~/roms/mslugx` and
`~/roms`.

Verified dump (SHA-1 of the files this project was tested with):

| File | Size | SHA-1 |
|---|---|---|
| `250-p1.p1` | 1,048,576 | `4c19f2e9824e606178ac1c9d4b0516fbaa625035` |
| `250-p2.ep1` | 4,194,304 | `18aaa7a3ba8da99f78c430e9be69ccde04bc04d9` |
| `250-c1.c1` | 8,388,608 | `c3e8a8ccdac0f8bddc4c3413277626532405fae2` |
| `250-c2.c2` | 8,388,608 | `554f600a3aa09c16c13c625299b087a79d0d15c5` |
| `250-c3.c3` | 8,388,608 | `c56646c62387bc1439d46610258c755beb8d7dd8` |
| `250-c4.c4` | 8,388,608 | `31be8ea2498001f68ce4b06b8b90acbf2dcab6af` |
| `250-c5.c5` | 8,388,608 | `d41069856df990a1a99d39fb263c8303389d5475` |
| `250-c6.c6` | 8,388,608 | `39be66287696829d243fb71b3fb8b7dc2bc3298f` |
| `250-s1.s1` | 131,072 | `2cc392ecde5d5afb28ddbaa1030552b48571dcfb` |
| `250-m1.m1` | 131,072 | `55769bad4860f64ef53a333e0da9e073db483d6a` |
| `250-v1.v1` | 4,194,304 | `ebfcc67204ff9677cf7972fd5b6b7faabf07280c` |
| `250-v2.v2` | 4,194,304 | `526c42ca9a388f7435569400e2f132e2724c71ff` |
| `250-v3.v3` | 2,097,152 | `45979d1edb1fc774a415d9386f98d7cb252a2043` |

BIOS files used: `sp-s2.sp1`, `sfix.sfix`, `sm1.sm1`, `000-lo.lo` from the
`neogeo` set. Other BIOS revisions can be selected with `--bios FILE`.

## Building

> **Source-only repository.** The CMake build files (`CMakeLists.txt`,
> `*.cmake`, the vendored toolkit's build scripts) are not published here;
> the steps below describe the author's build workspace. Upstream's test
> fixtures (`neogeorecomp/ext/musashi/test`, `ext/z80/roms`) and CI
> workflows are omitted as well — they belong to Musashi/z80, not to this
> port, and contain no game data either way. Everything else needed to read,
> review or port the code is present.

### Windows x64 (MSVC + CMake)

```powershell
# SDL2 2.32.10 development files are in deps/sdl2 (zlib licence)
powershell -ExecutionPolicy Bypass -File scripts\build-windows.ps1 `
    -RomDir C:\path\to\roms
# -> build-windows\Release\Metal Slug X.exe
powershell -ExecutionPolicy Bypass -File scripts\package-windows.ps1
# -> dist\windows\Metal Slug X-Windows-x64\ and its zip
```

`MSLUGX_ROM_DIR` is only needed to *recompile* — the generated C lives in
`build-windows/generated` and is never committed. A build without it produces
an interpreter-only player.

### Linux x86-64 / Steam Deck

```bash
sudo apt install build-essential cmake libsdl2-dev python3 wget
bash scripts/build-linux.sh /path/to/roms     # -> build-linux/metal-slug-x
bash packaging/appimage/build-appimage.sh /path/to/roms
# -> dist/steamdeck/Metal_Slug_X-SteamDeck-x86_64.AppImage
```

The AppImage bundles the SDL2 it was linked against (SteamOS ships a
different major), the desktop entry, a 256×256 original icon and the licence
texts. It does not bundle ROMs.

## Running

```
Metal Slug X.exe [--rom-path DIR] [--bios-path DIR] [--bios FILE]
                 [--headless] [--frames N] [--screenshot N:FILE]
                 [--input FILE] [--interp] [--verify] [--dump-misses FILE]
                 [--scale N] [--fullscreen] [--wav FILE] [--mute]
```

Typical checks:

```
# interpreted boot, for board-model work
metal-slug-x --headless --interp --frames 3000 --screenshot 2999:boot.png

# recompiled, verified, scripted play
metal-slug-x --headless --verify --frames 6000 --input tests/play.txt

# coverage number, and the entry points still interpreted
metal-slug-x --headless --frames 12000 --input tests/play_long.txt --dump-misses misses.txt

# audio capture + objective checks
metal-slug-x --headless --frames 12001 --input tests/play_long.txt --wav out.wav
python3 tests/check_audio.py out.wav
python3 tests/analyze_audio.py out.wav
```

`--verify` re-runs every native block in Musashi and compares registers,
flags and bus writes; it is the correctness gate, not a coverage number.

## Controls

| Input | Action |
|---|---|
| arrows / left stick | move |
| Z X C V / pad A B X Y | Neo Geo A B C D |
| 5 / pad Back | insert coin |
| 1 / Start | 1P start |
| 3 / left shoulder | select |
| 9 | service |
| F2 | test switch |
| F11 | toggle fullscreen (4:3 pillarboxed) |
| Esc | quit |

Steam Input: map the Deck's face buttons to A/B/X/Y, D-pad or left stick to
the arrows, Back to coin, Start to start and L1 to select. No custom Steam
Input profile is required for a standard XInput layout; the runtime reads
SDL's GameController mapping, so any pad SDL recognises works, and two pads
map to P1/P2.

## Repository layout

```
CMakeLists.txt          game + generator + player targets
src/game.c, game.h      the verified ng_game_t ROM layout
src/main.c              player: ng_main() with the generated table
src/recomp_main.c       generator: ng_recomp_main()
neogeorecomp/           toolkit (MIT), vendored; local generic fixes only
tests/                  input scripts + audio checks
packaging/appimage/     AppDir/AppImage build
packaging/windows/      packaged-build README and ROM helper
scripts/                build and packaging entry points
docs/                   compatibility report, test log
dist/                   the two deliverables (built, not committed)
```

The toolkit copy under `neogeorecomp/` is upstream
`sp00nznet/neogeorecomp` at `v0.2.0` (`af96b2b`) plus the generic fixes the
other ports in this workspace needed (MVS watchdog reset, bank-window guard,
protection-port slow path, KOF2000-style fixed-layer banking, power-of-two
sprite allocation, `--fullscreen`, the YM2610 M1 bank mask, frame-boundary
`audio_sync()`, and the SDL audio-stream output path). None of them are
title-specific.

## Measured results

From the runs recorded in [docs/TESTLOG.md](docs/TESTLOG.md), on the build
machine, against the owner's dump:

| Check | Result |
|---|---|
| ROM set | 17 files, all SHA-1s match; `NEO-GEO` at `$100`; bank IDs `00 01 02 03` |
| Interpreted boot | BIOS warning → title → Mission 1 (screenshots checked) |
| Native boot | 3,000 frames: 52,336,323 instructions, 100.00% native |
| `--verify` (Windows, 3,200 frames, `tests/play.txt`) | **2,105,133 blocks, 0 mismatches** |
| `--verify` (Linux, same script) | 2,105,178 blocks, 0 mismatches |
| Native coverage (19,000 frames, `tests/play_long.txt`) | **90.04% native** (302.5M native / 33.5M interpreted instructions), 34 uncovered entry points |
| Native coverage (3,200 frames, `tests/play.txt`) | 100.00% native |
| Speed (headless, MSVC Release) | 19,000 frames in 75.7 s = 251 fps = **4.2x real time** |
| Audio capture (202.8 s) | peak 32,767 (3 samples at full scale), RMS 4,326, L/R 1.008, longest silent run 4 s at a transition |
| Windows | windowed and fullscreen runs exit 0; audio device negotiated 55,555 Hz float, queue 73-78 ms, 0 stalls |
| AppImage | 23.4 MB, boots headless, fullscreen at 1280x800 → `dst 107,0 1066x800` (4:3 pillarbox) |

The 10% interpreted share is deliberate: the bank window can point at banks
1-3, whose code the v0.2.0 table does not describe. Those blocks run in
Musashi rather than executing a stale translation. `--verify` proves the
native blocks are correct; it does not claim the whole game is native.

## Known limitations

* Code reached through a *swapped* bank window runs in Musashi; see
  [Banked code](#banked-code). Correctness is unaffected, speed is.
* The build is x86-64 only. No ARM/Apple Silicon target is provided.
* Audio was validated by waveform analysis and timeline comparison, not by
  subjective listening on the target hardware.
* Physical Steam Deck, SteamOS Gaming Mode and Steam Input hardware were not
  available for this build; see [docs/COMPATIBILITY.md](docs/COMPATIBILITY.md).

## Licensing

* **Original project code** (game host, ROM layout, scripts, tests, docs):
  **PolyForm Noncommercial 1.0.0**, confirmed by the project owner on
  2026-10-27. See `LICENSE` and `LICENSE-STATUS.md`.
* **neogeorecomp**: MIT, Copyright (c) 2026 sp00nznet. Its `LICENSE`,
  `NOTICE` and `LICENSES/` are preserved.
* **Musashi** (MIT), **superzazu/z80** (MIT), **ymfm** (BSD-3-Clause),
  **SDL2** (zlib): see `THIRD_PARTY_NOTICES.md` and
  `neogeorecomp/LICENSES/`.
* **Game data**: no ROMs, BIOS images or ROM-derived artifacts (recompiled C,
  entry lists) are distributed. The game and its imagery remain SNK's.

PolyForm Noncommercial is not an open-source licence and does not permit
commercial redistribution. If any dependency's terms or the distribution
rights are unclear for your use, treat it as unresolved rather than relying
on this document as legal advice.

# Compatibility report — Metal Slug X

## Board

| Item | Value |
|---|---|
| System | SNK Neo Geo MVS (also AES-shaped ROM set; run on the MVS model) |
| Cartridge | NGM-250, plain PROGBK1/CHA256-class board |
| Program | 5 MB: 1 MB fixed + 4 MB banked, standard NEO-ZMC 1 MB banking at `$2FFFF0` |
| Protection | NEO-MVS PROGEOP ALTERA bit-stream device at `$2FFFE0-$2FFFEF` (emulated) |
| Encryption | none (no NEO-SMA, no NEO-CMC; no decrypt step in the build) |
| Fixed layer | 128 KB S ROM, plain 12-bit tile codes (`NG_FIX_BANK_NONE`) |
| Sound | M1 128 KB, V ROMs 10 MB, YM2610 at 8 MHz |
| BIOS | real `sp-s2.sp1` + `sfix.sfix` + `sm1.sm1` + `000-lo.lo`, no HLE |

MAME reference: `neogeo.cpp`, `ROM_START(mslugx)`, checked file by file
(names, sizes and SHA-1 in the README). The set includes the `250-p2.ep1`
program revision that MAME expects.

## ROM layout verification

| Check | Result |
|---|---|
| `NEO-GEO` signature at `$100` of the fixed bank after word swap | present |
| Cart header at `$000000` after word swap | `0010 F300 00C0 0402 00C0 0408 00C0 040E` (BIOS exception vectors) |
| P1/P2 both `ROM_LOAD16_WORD_SWAP`, P1 at `0`, P2 at `0x100000` | matches MAME, no half reordering |
| C ROM pairing `(c1,c2) (c3,c4) (c5,c6)`, 48 MB | matches MAME sprite region |
| V ROM concatenation 4+4+2 MB = 10 MB | matches MAME ADPCM-A region |
| M1 `250-m1.m1` 128 KB | matches `NEO_BIOS_AUDIO_128K` |

Code density check (word-swapped 68000 opcodes) confirms where the native
coverage limit applies: the fixed bank holds the engine (thousands of `RTS`
and `JSR abs.l`), while the four banked megabytes are almost entirely data
(58 `RTS`, 46 `JSR abs.l` across 4 MB). Banked code runs in Musashi when the
window is switched, but it is a small share of execution.

### The PROGEOP protection device

Metal Slug X is one of two SNK carts (with KOF '98) built on the **NEO-MVS
PROGEOP** board, which carries an ALTERA EPM7128 at `$2FFFE0-$2FFFEF`. During
boot the game verifies that the chip answers, then uses it to walk a bit table
held in its own fixed ROM:

| Address | Access | Behaviour |
|---|---|---|
| `$2FFFE0` | write | command = 0 (start a new read) |
| `$2FFFE2` / `$2FFFE4` | write | command \|= data |
| `$2FFFE6` | write | end of command |
| `$2FFFEA` | write | counter = 0, command = 0 (init) |
| `$2FFFEx` | read | command 1: next bit of the table, counter++ |
| `$2FFFEx` | read | command `$0FFF`: one bit selected by the work-RAM word |

Without it the boot self-test fails and the game prints its own
"THIS ROM CARTRIDGE IS FOR USE WITH ORIGINAL SNK BOARDS ONLY" screen and then
parks in a watchdog-kick loop with interrupts masked — which looks like a
hang at the BIOS warning, not like a protection problem. That was exactly the
first bring-up symptom of this port.

The device is implemented generically (`NG_PROT_TYPE_BITSTREAM` in the
toolkit, `src/game.c` supplies the table and selector addresses as cart data),
so a KOF '98 port can use the same mechanism with its own addresses.

## Hardware behaviour exercised

| Function | Implementation | Status |
|---|---|---|
| 68000 CPU | recompiled C + Musashi fallback/`--verify` | measured (see TESTLOG) |
| BIOS boot | real MVS system ROM, memory test, eyecatcher, coin/credit | boots |
| Cartridge banking | `$2FFFF0` write, 1 MB window, wrap guard | exercised in play |
| Sprite rendering | per-scanline, sticky chains, shrink, 96/line, auto-anim | visually checked |
| Fixed layer | 128 KB S ROM, palette banks | visually checked |
| Raster effects | LSPC timer IRQ | exercised by the attract loop |
| Z80 sound | M1 driver, NMI command latch, reply latch, ROM banking | audio captured |
| YM2610 | ymfm FM / SSG / ADPCM-A / ADPCM-B at 55,555 Hz | audio captured |
| SDL2 output | device-rate conversion via `SDL_AudioStream`, 60 ms cushion | smoke-tested |
| Input | keyboard + two SDL gamepads, coin/start/service/test | smoke-tested |
| Watchdog | `$300001` kick, board reset after 1,622,015 68k clocks | implemented (generic) |

## Not validated

* Physical Steam Deck / SteamOS hardware, Gaming Mode, Steam Input.
* Subjective audio listening on any device; only waveform/timeline analysis.
* Two-player sessions, service menu, DIP switches, memory card.
* Full-game completion; testing covers attract, coin/start and Mission 1.
* AES-specific behaviour (this build models the MVS board).

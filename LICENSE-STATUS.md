# License status

The **original project code** in this repository (the game host, ROM layout,
packaging scripts, tests and documentation) is licensed under the
**PolyForm Noncommercial License 1.0.0**. The project owner confirmed this
variant on 2026-10-27. The full license text is in `LICENSE`.

Required Notice: Copyright (c) 2026 the Metal Slug X Recompilation authors.

What this license does **not** cover
------------------------------------
* `neogeorecomp/` is the upstream toolkit by sp00nznet, MIT licensed. Its
  `LICENSE`, `NOTICE` and `LICENSES/` directory are preserved. Do not
  relicense those files under PolyForm.
* Musashi (MIT), superzazu/z80 (MIT) and ymfm (BSD-3-Clause) are vendored
  under `neogeorecomp/ext/`; their notices are preserved.
* SDL2 is zlib licensed; the Windows DLL and the AppImage bundle it under
  that license.
* The game ROMs, the Neo Geo BIOS, and anything generated from them
  (recompiled C, entry lists) are **not** part of this project's licensed
  source and are not distributed. Users supply their own legally obtained
  dumps.
* Game screenshots and captures contain SNK's copyrighted imagery and are
  **not** distributed in this repository or its release assets. Local test
  runs generate them under `shots/`, which is git-ignored.

PolyForm Noncommercial is not a free/open-source license and does not permit
commercial redistribution. Do not assume otherwise. If you need commercial
terms, contact the project owner.

See `THIRD_PARTY_NOTICES.md` for the complete attribution list.

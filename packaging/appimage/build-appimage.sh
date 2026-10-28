#!/usr/bin/env bash
# Build the Linux x86_64 player and package it as a Steam Deck AppImage.
#
# Prerequisites: gcc, g++, cmake 3.21+, make, libsdl2-dev, wget, strip.
# The user's ROMs are never bundled: the AppImage contains only the recompiled
# player, its libraries, the desktop entry, the icon and the documentation.
#
# Usage: ./packaging/appimage/build-appimage.sh [ROM_DIR]
# Default ROM_DIR=$ROOT/roms-src, output dist/steamdeck/...AppImage
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ROMS="${1:-$ROOT/roms-src}"
BUILD="$ROOT/build-linux"
APPDIR="$BUILD/AppDir"
NAME="Metal Slug X"
BIN="metal-slug-x"
OUT="$ROOT/dist/steamdeck/Metal_Slug_X-SteamDeck-x86_64.AppImage"

echo "== configure/build (Release) =="
cmake -S "$ROOT" -B "$BUILD" -DCMAKE_BUILD_TYPE=Release "-DMSLUGX_ROM_DIR=$ROMS"
cmake --build "$BUILD" --parallel "$(nproc)"

echo "== assemble AppDir =="
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin" "$APPDIR/usr/lib" \
         "$APPDIR/usr/share/applications" \
         "$APPDIR/usr/share/icons/hicolor/256x256/apps" \
         "$APPDIR/usr/share/doc/metal-slug-x"
cp "$BUILD/$BIN" "$APPDIR/usr/bin/$BIN"
strip --strip-unneeded "$APPDIR/usr/bin/$BIN" 2>/dev/null || true

# Bundle the SDL2 the build linked against; SteamOS's system copy may differ.
SDL=$(ldd "$BUILD/$BIN" | awk '/libSDL2-2\.0\.so\.0/{print $3; exit}')
if [ -n "$SDL" ]; then cp "$SDL" "$APPDIR/usr/lib/"; fi

cp "$ROOT/packaging/appimage/metal-slug-x.png" "$APPDIR/metal-slug-x.png"
cp "$ROOT/packaging/appimage/metal-slug-x.png" "$APPDIR/usr/share/icons/hicolor/256x256/apps/metal-slug-x.png"
cp "$ROOT/packaging/appimage/metal-slug-x.desktop" "$APPDIR/metal-slug-x.desktop"
cp "$ROOT/packaging/appimage/metal-slug-x.desktop" "$APPDIR/usr/share/applications/metal-slug-x.desktop"
cp "$ROOT/packaging/appimage/README.txt" "$APPDIR/usr/share/doc/metal-slug-x/README.txt"
cp "$ROOT/LICENSE" "$APPDIR/usr/share/doc/metal-slug-x/LICENSE.txt"
cp "$ROOT/LICENSE-STATUS.md" "$APPDIR/usr/share/doc/metal-slug-x/LICENSE-STATUS.txt"
cp "$ROOT/THIRD_PARTY_NOTICES.md" "$APPDIR/usr/share/doc/metal-slug-x/THIRD_PARTY_NOTICES.txt"
mkdir -p "$APPDIR/usr/share/doc/metal-slug-x/LICENSES"
cp "$ROOT/neogeorecomp/LICENSE" "$APPDIR/usr/share/doc/metal-slug-x/LICENSES/neogeorecomp.txt"
cp "$ROOT/neogeorecomp/NOTICE" "$APPDIR/usr/share/doc/metal-slug-x/LICENSES/neogeorecomp-NOTICE.txt"
cp "$ROOT/neogeorecomp/LICENSES/"*.txt "$APPDIR/usr/share/doc/metal-slug-x/LICENSES/"

cat > "$APPDIR/AppRun" <<'EOF'
#!/bin/sh
HERE=$(dirname "$(readlink -f "$0")")
export LD_LIBRARY_PATH="$HERE/usr/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

# Find a ROM directory beside the AppImage or in the usual Deck locations.
has_rom=0
for a in "$@"; do [ "$a" = "--rom-path" ] && has_rom=1; done
if [ "$has_rom" = 0 ] && [ -n "${APPIMAGE:-}" ]; then
    for d in "$(dirname "$APPIMAGE")/roms" \
             "$(dirname "$APPIMAGE")/roms/mslugx" \
             "$HOME/.local/share/mslugx/roms" \
             "$HOME/Emulation/roms/mslugx" \
             "$HOME/roms/mslugx" "$HOME/roms"; do
        if [ -d "$d" ]; then set -- --rom-path "$d" "$@"; has_rom=1; break; fi
    done
fi

# Steam Deck / Gaming Mode wants a fullscreen game. Keep --headless and an
# explicit --scale or --fullscreen from being overridden.
add_fs=1
for a in "$@"; do
    case "$a" in --headless|--fullscreen|--scale) add_fs=0;; esac
done
[ "$add_fs" = 1 ] && set -- --fullscreen "$@"

exec "$HERE/usr/bin/metal-slug-x" "$@"
EOF
chmod +x "$APPDIR/AppRun"

echo "== appimagetool =="
mkdir -p "$ROOT/dist/steamdeck"
TOOL="${APPIMAGETOOL:-$BUILD/appimagetool.AppImage}"
if [ ! -x "$TOOL" ]; then
    wget -q -O "$TOOL" \
      https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage
    chmod +x "$TOOL"
fi
ARCH=x86_64 "$TOOL" --appimage-extract-and-run --no-appstream "$APPDIR" "$OUT"
chmod +x "$OUT"
echo "wrote $OUT"

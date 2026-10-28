#!/usr/bin/env bash
# Build the Linux x86_64 player (headless + SDL2 window).
#
#   bash scripts/build-linux.sh [ROM_DIR] [BUILD_DIR]
#   JOBS=6 bash scripts/build-linux.sh
#
# ROM_DIR defaults to <repo>/roms-src. Nothing derived from the ROMs is
# written outside the build directory.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ROMS="${1:-$ROOT/roms-src}"
BUILD="${2:-$ROOT/build-linux}"
JOBS="${JOBS:-$(nproc)}"
cmake -S "$ROOT" -B "$BUILD" -DCMAKE_BUILD_TYPE=Release "-DMSLUGX_ROM_DIR=$ROMS"
cmake --build "$BUILD" --parallel "$JOBS"
echo "built $BUILD/metal-slug-x"

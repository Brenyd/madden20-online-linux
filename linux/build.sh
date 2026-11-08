#!/usr/bin/env bash
# Madden 20 Online - Linux build.
#
# Builds the patched shadPS4 core natively, stages build/payload (what the installer copies), and packs
# dist/Madden20Online-linux-x86_64.tar.gz. Run from anywhere:
#     linux/build.sh            # build core + stage + tarball
#     linux/build.sh --stage    # skip the compile, re-stage with an existing core
#
# Needs (Arch / CachyOS):
#   sudo pacman -S --needed base-devel clang cmake ninja git python python-cryptography python-pillow tk \
#       vulkan-headers vulkan-icd-loader sdl3 libx11 libxext libxrandr libxcursor libxi libxss wayland \
#       wayland-protocols libxkbcommon alsa-lib libpulse pipewire openssl zlib libpng libusb
# Debian/Ubuntu: see linux/README.md.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
EMU="$REPO/emulator"
BUILD="$EMU/build-linux"
JOBS="${JOBS:-$(nproc)}"
STAGE_ONLY=0
[[ "${1:-}" == "--stage" ]] && STAGE_ONLY=1

say() { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
die() { printf '\033[1;31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }

if (( ! STAGE_ONLY )); then
    CC="${CC:-clang}"; CXX="${CXX:-clang++}"
    for t in "$CC" "$CXX" cmake ninja git python3; do
        command -v "$t" >/dev/null || die "missing '$t' - see the dependency list at the top of this script"
    done
    # The core is C++23: clang 19+ (relaxed constexpr) and a libstdc++ with std::ranges::to (GCC 14+).
    clang_major=$("$CXX" -dumpversion | cut -d. -f1)
    (( clang_major >= 19 )) || die "$CXX is clang $clang_major; clang 19 or newer is needed (Ubuntu 24.04: apt install clang-19 g++-14, then CC=clang-19 CXX=clang++-19 linux/build.sh)"
    echo '#include <ranges>
#include <vector>
int main(){auto v=std::views::iota(0,3)|std::ranges::to<std::vector>();return v.size()!=3;}' > /tmp/m20_ranges_check.cpp
    "$CXX" -std=c++23 -o /dev/null /tmp/m20_ranges_check.cpp 2>/dev/null \
        || die "your C++ standard library lacks std::ranges::to - install GCC 14+ (libstdc++) alongside clang"
    rm -f /tmp/m20_ranges_check.cpp

    say "Fetching emulator submodules (pinned commits)"
    cd "$REPO"
    # android.googlesource.com is unreachable from some networks; the GitHub mirror carries the same commits.
    git config submodule.emulator/externals/aacdec/fdk-aac.url https://github.com/mstorsjo/fdk-aac
    git submodule sync --quiet -- emulator/externals/aacdec/fdk-aac
    git submodule update --init --recursive --jobs 4 \
        || die "submodule fetch failed - check your connection and re-run"

    say "Configuring the patched shadPS4 core (clang, Release, Madden fixes on)"
    cmake -S "$EMU" -B "$BUILD" -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_C_COMPILER="$CC" -DCMAKE_CXX_COMPILER="$CXX" \
        -DENABLE_NBA_2K14_COMPATIBILITY=ON \
        -DENABLE_UPDATER=OFF \
        -DENABLE_DISCORD_RPC=OFF \
        -DFETCHCONTENT_SOURCE_DIR_FMT="$EMU/externals/fmt" \
        ${EXTRA_CMAKE_ARGS:-}

    say "Compiling (this takes a while; JOBS=$JOBS)"
    ninja -C "$BUILD" -j "$JOBS" shadps4
fi

CORE="$BUILD/shadps4"
[[ -x "$CORE" ]] || die "no core at $CORE - run without --stage first"

say "Staging build/payload"
python3 -I - "$REPO" "$CORE" <<'PY'
import shutil, sys
from pathlib import Path
repo, core = Path(sys.argv[1]), Path(sys.argv[2])
RUNTIME_TOOLS = ["muthead_scrape.py", "muthead_parse.py", "art_download.py", "art_shrink.py", "pack_art.py"]
pay = repo / "build" / "payload"
if pay.exists():
    shutil.rmtree(pay)
(pay / "core").mkdir(parents=True)
shutil.copy2(core, pay / "core" / "shadps4")
ign = shutil.ignore_patterns("__pycache__", "*.pyc", "logs", "certs")
for sub in ("server", "mutdata", "modroot", "dump"):
    shutil.copytree(repo / sub, pay / sub, ignore=ign)
(pay / "tools").mkdir()
for t in RUNTIME_TOOLS:
    shutil.copy2(repo / "tools" / t, pay / "tools" / t)
shutil.copytree(repo / "installer" / "templates", pay / "templates")
icon = repo / "linux" / "madden20-online.png"
if icon.exists():
    shutil.copy2(icon, pay / icon.name)
print("staged", pay)
PY

say "Packing dist/Madden20Online-linux-x86_64.tar.gz"
PKG="$REPO/build/Madden20Online-linux"
rm -rf "$PKG"
mkdir -p "$PKG" "$REPO/dist"
cp -a "$REPO/build/payload" "$PKG/payload"
cp "$REPO/installer/madden20_online.py" "$PKG/"
cp "$REPO/linux/setup.sh" "$PKG/setup.sh"
cp "$REPO/linux/README.md" "$PKG/README.md"
cp "$REPO/LICENSE" "$PKG/"
chmod +x "$PKG/setup.sh"
tar -C "$REPO/build" -czf "$REPO/dist/Madden20Online-linux-x86_64.tar.gz" Madden20Online-linux
say "Done: dist/Madden20Online-linux-x86_64.tar.gz"

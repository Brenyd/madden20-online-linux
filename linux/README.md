# Madden 20 Online — Linux

Native Linux build of Madden 20 Online: the same local EA server and the same patched shadPS4 core, compiled
for Linux. No Wine, no root, nothing contacts EA.

**You need:** your own extracted Madden NFL 20 PS4 game (CUSA13265, version 01.00), x86-64 Linux, a Vulkan GPU
(Mesa RADV or NVIDIA proprietary), a controller, Python 3 with tkinter, `cryptography` and Pillow.

## Install from a release tarball

```sh
tar xzf Madden20Online-linux-x86_64.tar.gz
cd Madden20Online-linux
./setup.sh                      # pick the game folder + install folder (default ~/Madden20Online)
```

Then start **Madden 20 Online** from your app menu (or run `~/Madden20Online/madden20-online`), click
**Download card data** once, then **Play**.

Python packages:

| Distro | Command |
|---|---|
| Arch / CachyOS / Manjaro | `sudo pacman -S --needed python python-cryptography python-pillow tk` |
| Debian / Ubuntu / Mint | `sudo apt install python3 python3-cryptography python3-pil python3-tk` |
| Fedora | `sudo dnf install python3 python3-cryptography python3-pillow python3-tkinter` |

No window? Everything also works from a terminal:

```sh
./setup.sh --install /path/to/CUSA13265 ~/Madden20Online
~/Madden20Online/madden20-online --download-cards          # add --no-art to skip the ~1 GB card art
~/Madden20Online/madden20-online --play
```

## Build from source

```sh
git clone https://github.com/<you>/madden20-online-linux
cd madden20-online-linux
linux/build.sh                  # submodules -> cmake/ninja core -> build/payload -> dist/*.tar.gz
```

Build dependencies (Arch / CachyOS):

```sh
sudo pacman -S --needed base-devel clang cmake ninja git python python-cryptography python-pillow tk \
    vulkan-headers vulkan-icd-loader libx11 libxext libxrandr libxcursor libxi libxss libxtst wayland \
    wayland-protocols libxkbcommon alsa-lib libpulse pipewire openssl zlib libpng libusb
```

Debian / Ubuntu:

```sh
sudo apt install build-essential clang cmake ninja-build git python3 python3-cryptography python3-pil \
    python3-tk libvulkan-dev libx11-dev libxext-dev libxrandr-dev libxcursor-dev libxi-dev libxss-dev \
    libxtst-dev libwayland-dev wayland-protocols libxkbcommon-dev libasound2-dev libpulse-dev \
    libpipewire-0.3-dev libssl-dev zlib1g-dev libpng-dev libusb-1.0-0-dev libudev-dev
```

Clang 19 or newer and GCC 14+ (for its C++ standard library) — Arch/CachyOS/Fedora 41+ already have them. On
Ubuntu 24.04 / Mint 22 add `clang-19 g++-14` and run `CC=clang-19 CXX=clang++-19 linux/build.sh`. The build needs network access for the submodules (and, if your system has no abseil, protobuf
fetches it). `JOBS=4 linux/build.sh` limits parallel jobs on low-RAM machines; `linux/build.sh --stage` re-packs
without recompiling.

To run straight from the repo without packing: `MADDEN_PAYLOAD=build/payload python3 -I installer/madden20_online.py`.

## What's different from the Windows build

| | Windows | Linux |
|---|---|---|
| Core | `core\shadps4.exe` (clang-cl) + VC++ DLLs | `core/shadps4` (clang) |
| HTTPS catch-all port | `:443` | `:42443` — `:443` needs root on Linux. The launcher sets `MADDEN_HTTPS_PORT=42443` and the patched core's `EAREDIRECT` sends redirected `*.ea.com:443` traffic there. |
| Launcher | PyInstaller one-file exe | `madden20-online` sh wrapper + `madden20_online.py`, system Python |
| Shortcut | Desktop `.lnk` | `~/.local/share/applications/madden20-online.desktop` (+ Desktop copy if you have one) |
| Path check | Refuses non-ANSI paths | Not needed — any path works |

Everything else — the Blaze/HTTP servers, flags in `modroot/flags/`, card scraper, game-file checks — is the same
code as upstream.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `tkinter is missing` | Install your distro's Tk package (table above), or use the `--install/--play` commands. |
| Ports in use | Another copy of the servers is running: `pkill -f "madden20_online.py --serve"`. |
| Black screen, `vkCreateDevice` errors | Check `vulkaninfo`; on hybrid laptops start with `prime-run ~/Madden20Online/madden20-online` (NVIDIA) or `DRI_PRIME=1` (AMD). |
| Stuck on LOADING GAME / Controller Disconnected | Same as Windows — restart the game. |
| Server errors | Logs are in `~/Madden20Online/server/logs/`; emulator log in `~/Madden20Online/core/user/log/`. |

#!/bin/sh
# Madden 20 Online - Linux setup.
#   ./setup.sh                          setup window (pick the game folder + install folder)
#   ./setup.sh --install GAME DEST      unattended install, no window
# After installing, start the game with  <install folder>/madden20-online  (or the app-menu entry).
HERE="$(cd "$(dirname "$0")" && pwd)"
PY="${PYTHON:-python3}"

if ! "$PY" -c 'import cryptography' 2>/dev/null; then
    echo "Python 'cryptography' is missing. Arch: sudo pacman -S python-cryptography   Debian/Ubuntu: sudo apt install python3-cryptography" >&2
    exit 1
fi
if ! "$PY" -c 'import PIL' 2>/dev/null; then
    echo "Note: Python Pillow is missing - card art processing will fail. Arch: python-pillow   Debian/Ubuntu: python3-pil" >&2
fi

export MADDEN_PAYLOAD="$HERE/payload"
exec "$PY" -I "$HERE/madden20_online.py" "$@"

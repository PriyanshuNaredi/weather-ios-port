#!/bin/bash
set -u
T="$HOME/.config/xtool/data/XTLAuthToken"
echo "== BEFORE (metadata only) =="
stat -c 'perms=%a | owner=%U:%G | size=%s | mtime=%y' "$T"
chmod 600 "$T"
echo; echo "== AFTER =="
stat -c 'perms=%a | owner=%U:%G | size=%s | mtime=%y' "$T"
echo; echo "== parent dir data/ =="
stat -c 'dir=data | perms=%a | owner=%U:%G' "$HOME/.config/xtool/data"
chmod 700 "$HOME/.config/xtool/data"
echo "data/ tightened to 700:"
stat -c 'perms=%a | owner=%U:%G' "$HOME/.config/xtool/data"

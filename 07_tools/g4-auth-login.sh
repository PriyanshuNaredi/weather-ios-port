#!/bin/bash
# G4: interactive Apple login — YOU type credentials; nothing is captured here.
# No tee, no redirect, no logging of this session by design (rule 3).
X="/mnt/c/Users/naredi/Downloads/Android Weather APK Reverse Engineering → Native iOS Port/07_tools/xtool/xtool-x86_64.AppImage"
"$X" auth login

#!/bin/bash
# G1 checksum verification: GPG-verify the Swift 6.4.2 Ubuntu 26.04 tarball
# against swift.org's official key bundle. Keyring lives in $HOME/.gpg-weather
# (WSL ext4; gnupg refuses mode-open dirs on /mnt/c). Documented deviation.
set -e
D="/mnt/c/Users/naredi/Downloads/Android Weather APK Reverse Engineering → Native iOS Port/07_tools/swift-linux"
gpg --homedir "$HOME/.gpg-weather" --keyid-format long \
  --verify "$D/swift-6.4.2-RELEASE-ubuntu26.04.tar.gz.sig" \
           "$D/swift-6.4.2-RELEASE-ubuntu26.04.tar.gz"

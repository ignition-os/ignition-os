#!/usr/bin/env bash
set -euo pipefail

# 1) gpg 2.4+ sometimes needs this flag for older keys
GPG_CONF="/etc/pacman.d/gnupg/gpg.conf"
if ! grep -q "^allow-weak-key-signatures" "$GPG_CONF" 2>/dev/null; then
  echo "allow-weak-key-signatures" >> "$GPG_CONF"
fi

# 2) Initialize keyring and import Arch + BlackArch keys
pacman-key --init || true
pacman-key --populate archlinux || true
pacman-key --populate blackarch || true   # provided by blackarch-keyring pkg

# 3) Lock the BlackArch repo back to signed packages
# Replace only the first SigLevel that belongs to [blackarch]
awk -v RS= -v ORS="\n\n" '
  $0 ~ /^\[blackarch\]/ {
    sub(/SigLevel[^\n]*/, "SigLevel = PackageRequired", $0)
  }
  { print }
' /etc/pacman.conf > /etc/pacman.conf.tmp
mv /etc/pacman.conf.tmp /etc/pacman.conf

# 4) Refresh databases with proper signatures and install can-utils (signed)
pacman -Syy --noconfirm
pacman -S --noconfirm can-utils


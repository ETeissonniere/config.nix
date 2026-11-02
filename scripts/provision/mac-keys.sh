#!/usr/bin/env bash
set -euo pipefail

if [ "$(uname -s)" != Darwin ] || [ "$(id -u)" = 0 ]; then
    echo 'Run this on the new Mac as your normal logged-in user.' >&2
    exit 1
fi
# Provision these identities before enrollment, as described in the README.
test -s "$HOME/.ssh/scauth/default/id_ecdsa_sk.pub"
test -s /etc/nix/straylight_builder_ed25519.pub
umask 077
mkdir -p "$HOME/.config/age"
identity="$HOME/.config/age/identity.key"
if [ ! -e "$identity" ]; then
    age-plugin-se keygen --pq --access-control any-biometry-or-passcode -o "$identity"
fi
age-plugin-se recipients --pq -i "$identity" -o "$HOME/.config/age/recipient.pub"
echo 'Public keys are ready. Run just mac-enroll <host> on wintermute.'

#!/usr/bin/env bash
set -euo pipefail

host=${1:?Usage: mac-keys.sh host}
case "$host" in
    ''|*[!a-z0-9-]*) echo 'Invalid host name.' >&2; exit 1 ;;
esac
if [ "$(uname -s)" != Darwin ] || [ "$(id -u)" = 0 ]; then
    echo 'Run this on the new Mac as your normal logged-in user.' >&2
    exit 1
fi
cd "$(dirname "$0")/../.."
test -f "hosts/$host/darwin-configuration.nix"
umask 077

# Reuse Home Manager's actual declaration instead of maintaining a bootstrap copy.
scauth_config=$(mktemp)
trap 'rm -f "$scauth_config"' EXIT
nix --extra-experimental-features 'nix-command flakes' eval --raw \
    "path:$PWD#darwinConfigurations.$host.config" \
    --apply 'config: (builtins.getAttr config.me.username config.home-manager.users).xdg.configFile."scauth/config.json".text' \
    > "$scauth_config"
scauth reconcile "$scauth_config"

builder=/etc/nix/straylight_builder_ed25519
if [ ! -e "$builder" ]; then
    sudo /usr/bin/ssh-keygen -t ed25519 -N "" -C "$host-builder" -f "$builder"
fi
test -s "$HOME/.ssh/scauth/default/id_ecdsa_sk.pub"
test -s "$builder.pub"
mkdir -p "$HOME/.config/age"
identity="$HOME/.config/age/identity.key"
if [ ! -e "$identity" ]; then
    age-plugin-se keygen --pq --access-control any-biometry-or-passcode -o "$identity"
fi
age-plugin-se recipients --pq -i "$identity" -o "$HOME/.config/age/recipient.pub"

public_key() {
    if ! awk -v type="$2" 'NR != 1 || $1 != type { exit 1 } END { if (NR != 1) exit 1 }' "$1"; then
        echo "Expected one $2 public key." >&2
        return 1
    fi
    /usr/bin/ssh-keygen -lf "$1" >&2
    awk '{print $1 " " $2}' "$1"
}
ssh_public=$(public_key "$HOME/.ssh/scauth/default/id_ecdsa_sk.pub" sk-ecdsa-sha2-nistp256@openssh.com)
builder_public=$(public_key "$builder.pub" ssh-ed25519)
echo 'Add these public SSH keys to modules/common/keys.nix:'
printf '  "%s-ssh" = "%s";\n' "$host" "$ssh_public"
printf '  "%s-builder" = "%s";\n' "$host" "$builder_public"
printf '\nSave this public age recipient as secrets/recipients/%s.pub:\n' "$host"
cat "$HOME/.config/age/recipient.pub"

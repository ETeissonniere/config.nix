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
local_host=$(/usr/sbin/scutil --get LocalHostName | tr '[:upper:]' '[:lower:]')
if [ "$host" != "$local_host" ]; then
    echo "Run this on $host; this Mac is $local_host." >&2
    exit 1
fi
cd "$(dirname "$0")/../.."
test -f "hosts/$host/darwin-configuration.nix"
umask 077

# Home Manager and Darwin activation already provision these two identities.
builder=/etc/nix/straylight_builder_ed25519
if [ ! -s "$HOME/.ssh/scauth/default/id_ecdsa_sk.pub" ] || [ ! -s "$builder.pub" ]; then
    echo "Run just host=$host switch locally first to create the SSH and builder keys." >&2
    exit 1
fi
mkdir -p "$HOME/.config/age"
identity="$HOME/.config/age/identity.key"
if [ ! -e "$identity" ]; then
    age-plugin-se keygen --pq --access-control any-biometry-or-passcode -o "$identity"
fi
# age-plugin-se 0.2.1 ignores --pq in its recipients command.
# Key generation saves the post-quantum public recipient alongside the identity.
recipient=$(awk '/^# public key \(post-quantum\): age1tagpq1/ { print $5; count++ } END { if (count != 1) exit 1 }' "$identity")
printf '%s\n' "$recipient" > "$HOME/.config/age/recipient.pub"

public_key() {
    if ! awk -v type="$2" 'NR != 1 || $1 != type { exit 1 } END { if (NR != 1) exit 1 }' "$1"; then
        echo "Expected one $2 public key." >&2
        return 1
    fi
    /usr/bin/ssh-keygen -lf "$1" >&2 || return 1
    awk '{print $1 " " $2}' "$1"
}
ssh_public=$(public_key "$HOME/.ssh/scauth/default/id_ecdsa_sk.pub" sk-ecdsa-sha2-nistp256@openssh.com)
builder_public=$(public_key "$builder.pub" ssh-ed25519)
echo 'Add this Mac to macs in lib/keys.nix:'
printf '    %s = {\n      ssh = "%s";\n      builder = "%s";\n    };\n' "$host" "$ssh_public" "$builder_public"
printf '\nSave this public age recipient as secrets/recipients/%s.pub:\n' "$host"
cat "$HOME/.config/age/recipient.pub"

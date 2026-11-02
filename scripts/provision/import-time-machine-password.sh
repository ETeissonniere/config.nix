#!/usr/bin/env bash
set -euo pipefail
host=${1:?Usage: import-time-machine-password.sh host}
case "$host" in
    wintermute) ;;
    *) echo 'Only wintermute has an existing backup password to import.' >&2; exit 1 ;;
esac
cd "$(dirname "$0")/../.."
test -f "hosts/$host/darwin-configuration.nix"
destination="secrets/$host/time-machine-password.age"
if [ -e "$destination" ]; then
    echo "Already saved: $destination. Refusing to replace a backup password." >&2
    exit 1
fi
umask 077
mkdir -p "secrets/$host"
output=$(mktemp "secrets/$host/.time-machine-password.XXXXXX")
trap 'unset password; rm -f "$output"' EXIT
IFS= read -r -s -p "Existing $host Time Machine encryption password: " password
printf '\n' >&2
test -n "$password"
printf '%s' "$password" | age --encrypt \
    -R secrets/recipients/wintermute.pub -R secrets/recipients/recovery.pub -o "$output"
unset password
ln "$output" "$destination"
echo "Saved encrypted password to $destination. The backup was not modified."

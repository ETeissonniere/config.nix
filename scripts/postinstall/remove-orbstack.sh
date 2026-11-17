#!/usr/bin/env bash
set -euo pipefail

# Run before switching away from OrbStack so its own integration uninstaller is available.
if [ "$(uname -s)" != Darwin ] || [ "$(id -u)" = 0 ]; then
    echo 'Run on each Mac as your normal logged-in user, before just switch.' >&2
    exit 1
fi
if [ "${1:-}" != --delete-all-data ]; then
    echo 'Usage: remove-orbstack.sh --delete-all-data' >&2
    echo 'Permanently deletes all OrbStack containers, images, volumes, and Linux machines.' >&2
    exit 1
fi
command -v jq >/dev/null
command -v orbctl >/dev/null
sudo -v

# Use the same integration removal command as the upstream Homebrew cask.
orbctl stop
orbctl _internal brew-uninstall
if pgrep -x OrbStack >/dev/null; then
    osascript -e 'tell application id "dev.kdrag0n.MacVirt" to quit'
fi

helper=dev.orbstack.OrbStack.privhelper
if sudo launchctl print "system/$helper" >/dev/null 2>&1; then
    sudo launchctl bootout "system/$helper"
fi
sudo rm -f "/Library/LaunchDaemons/$helper.plist" "/Library/PrivilegedHelperTools/$helper"

# Remove only links owned by OrbStack; keep other Docker installations intact.
shopt -s nullglob
for link in /usr/local/bin/* /opt/homebrew/bin/* /var/run/docker.sock \
    "$HOME"/.docker/cli-plugins/* "$HOME"/.docker/run/docker.sock \
    "$HOME"/.local/bin/*; do
    [ -L "$link" ] || continue
    case "$(readlink "$link")" in
        *OrbStack.app/*|*/.orbstack/*|/nix/store/*-orbstack-*/*) sudo rm -- "$link" ;;
    esac
done

# Docker configuration can also contain credentials and unrelated contexts.
config="$HOME/.docker/config.json"
if [ -f "$config" ]; then
    temporary=$(mktemp "$HOME/.docker/config.json.XXXXXX")
    trap 'rm -f "$temporary"' EXIT
    jq 'if .currentContext == "orbstack" then del(.currentContext) else . end |
        if .credsStore == "orbstack" then del(.credsStore) else . end' "$config" > "$temporary"
    chmod "$(stat -f %Lp "$config")" "$temporary"
    mv "$temporary" "$config"
    trap - EXIT
fi
for metadata in "$HOME"/.docker/contexts/meta/*/meta.json; do
    if jq -e '.Name == "orbstack"' "$metadata" >/dev/null; then
        context=$(basename "$(dirname "$metadata")")
        rm -rf "${metadata%/meta.json}" "$HOME/.docker/contexts/tls/$context"
    fi
done

# Match the upstream cask's zap paths, including the VM disks in the group container.
rm -rf "$HOME/.orbstack" \
    "$HOME"/Library/Application\ Scripts/*.dev.orbstack \
    "$HOME"/Library/Group\ Containers/*.dev.orbstack \
    "$HOME/Library/Caches/dev.kdrag0n.MacVirt" \
    "$HOME/Library/Caches/SentryCrash/OrbStack" \
    "$HOME/Library/HTTPStorages/dev.kdrag0n.MacVirt" \
    "$HOME/Library/HTTPStorages/dev.kdrag0n.MacVirt.binarycookies" \
    "$HOME/Library/Preferences/dev.kdrag0n.MacVirt.plist" \
    "$HOME/Library/Saved Application State/dev.kdrag0n.MacVirt.savedState" \
    "$HOME/Library/WebKit/dev.kdrag0n.MacVirt" \
    "$HOME/Library/Logs/OrbStack"
# This is OrbStack's virtual filesystem mount point, not an ordinary data directory.
if mount | grep -F " on $HOME/OrbStack (" >/dev/null; then
    echo 'OrbStack filesystem is still mounted; refusing to delete its mount point.' >&2
    exit 1
fi
if [ -d "$HOME/OrbStack" ]; then
    rm -f "$HOME/OrbStack/README.txt"
    rmdir "$HOME/OrbStack"
fi
sudo rm -rf /Applications/OrbStack.app

# Do not silently leave stale shell or SSH integration after the vendor uninstaller.
remaining=0
for file in "$HOME"/.zshrc "$HOME"/.zprofile "$HOME"/.bashrc "$HOME"/.bash_profile \
    "$HOME"/.profile "$HOME"/.ssh/config "$HOME"/.config/fish/config.fish \
    "$HOME"/.config/fish/conf.d/*.fish; do
    if [ -f "$file" ] && grep -qiE 'orbstack|MacVirt' "$file"; then
        echo "Remove remaining OrbStack integration from: $file" >&2
        remaining=1
    fi
done
if [ "$remaining" = 1 ]; then
    exit 1
fi

echo 'OrbStack data removed. Run just switch, then container system start.'
echo 'Old Nix generations retain OrbStack until they are expired and garbage-collected.'

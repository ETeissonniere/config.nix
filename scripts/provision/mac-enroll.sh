#!/usr/bin/env bash
set -euo pipefail

host=${1:?Usage: mac-enroll.sh host [user@address]}
case "$host" in
    ''|*[!a-z0-9-]*) echo 'Invalid host name.' >&2; exit 1 ;;
esac
address=${2:-$host.local}
case "$address" in
    -*|*[!a-zA-Z0-9@._:-]*) echo 'Invalid SSH address.' >&2; exit 1 ;;
esac
cd "$(dirname "$0")/../.."
test -f "hosts/$host/darwin-configuration.nix"
recipient="secrets/recipients/$host.pub"
if [ -e "$recipient" ]; then
    echo "Already enrolled: $recipient. Refusing to replace keys." >&2
    exit 1
fi
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
ssh "$address" 'cat ~/.ssh/scauth/default/id_ecdsa_sk.pub' > "$scratch/ssh.pub"
ssh "$address" 'cat /etc/nix/straylight_builder_ed25519.pub' > "$scratch/builder.pub"
ssh "$address" 'cat ~/.config/age/recipient.pub' > "$scratch/age.pub"
validate_public_key() {
    if ! awk -v type="$2" 'NR != 1 || $1 != type { exit 1 } END { if (NR != 1) exit 1 }' "$1"; then
        echo "Expected one $2 public key." >&2
        return 1
    fi
    ssh-keygen -lf "$1"
}
validate_public_key "$scratch/ssh.pub" sk-ecdsa-sha2-nistp256@openssh.com
validate_public_key "$scratch/builder.pub" ssh-ed25519
if ! awk 'NR != 1 || $0 !~ /^age1tagpq1[0-9a-z]+$/ { exit 1 } END { if (NR != 1) exit 1 }' "$scratch/age.pub"; then
    echo 'Expected one post-quantum Secure Enclave recipient.' >&2
    exit 1
fi

# Keep the catalog human-edited; verify it matches this Mac before rekeying.
missing=0
for role in ssh builder; do
    material=$(awk '{print $1 " " $2}' "$scratch/$role.pub")
    registered=$(nix --extra-experimental-features 'nix-command flakes' eval --raw \
        --file modules/common/keys.nix --apply "keys: keys.\"$host-$role\" or \"\"")
    if [ -z "$registered" ]; then
        printf '  "%s-%s" = "%s";\n' "$host" "$role" "$material"
        missing=1
    elif [ "$(printf '%s\n' "$registered" | awk '{print $1 " " $2}')" != "$material" ]; then
        echo "The $host-$role entry in modules/common/keys.nix differs from this Mac. Refusing to replace it." >&2
        exit 1
    fi
done
if [ "$missing" = 1 ]; then
    echo 'Add the entries above to modules/common/keys.nix, then run mac-enroll again.' >&2
    exit 1
fi

# Roll back the new recipient if rekeying fails, so enrollment can be retried.
cleanup() {
    rm -rf "$scratch"
    if [ "${enrolled:-0}" != 1 ]; then
        rm -f "$recipient"
    fi
}
trap cleanup EXIT
cp "$scratch/age.pub" "$recipient"
AGENIX_IDENTITY="${AGENIX_IDENTITY:-$HOME/.config/age/identity.key}" \
    nix --extra-experimental-features 'nix-command flakes' run "path:$PWD#agenix-rekey"
# agenix-rekey can exit successfully after a secret fails to rekey. Evaluating
# the enrolled host requires its ciphertext and leaves failures retryable.
nix --extra-experimental-features 'nix-command flakes' eval "path:$PWD#configurationPaths.$host" >/dev/null
enrolled=1
echo "Enrolled $host. Review the diff, run just check-all, and deploy server access."
echo "Configure Time Machine in macOS before switching $host with this enrolled checkout."

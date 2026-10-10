# Secrets

Use PQ Secure Enclave identities daily and a passphrase-encrypted PQ age key for
offline recovery. Keep private identities outside Git.

## Enroll

Run in a terminal on a Mac with Secure Enclave PQ support. Stop on any error;
do not overwrite an existing identity.

```fish
nix shell --inputs-from . nixpkgs#age nixpkgs#age-plugin-se -c fish
umask 077
set key_dir "$HOME/.config/agenix"
mkdir -p "$key_dir"
chmod 700 "$key_dir"
set scratch (mktemp -d)

if not test -e "$key_dir/secure-enclave-pq.identity"
    age-plugin-se keygen --pq --access-control=any-biometry-or-passcode \
        -o "$key_dir/secure-enclave-pq.identity"; or exit 1
end
string replace -rf '^# public key \(post-quantum\): (age1tagpq1[0-9a-z]+)$' '$1' \
    < "$key_dir/secure-enclave-pq.identity" > "$scratch/mac.pub"; or exit 1
test (count (cat "$scratch/mac.pub")) -eq 1; or exit 1
```

The pinned plugin's `recipients --pq` ignores the PQ flag, so use the PQ comment
above. The private identity only works on this Mac.

Create the recovery key **once**, using a strong, unique passphrase at the prompt:

```fish
test ! -e secrets/master-keys/recovery.pub; or exit 1
test ! -e "$key_dir/recovery-pq.age"; or exit 1
age-keygen -pq | age -p -o "$key_dir/recovery-pq.age"
set generation_status $pipestatus
test "$generation_status[1]" -eq 0; and test "$generation_status[2]" -eq 0; or exit 1
age -d "$key_dir/recovery-pq.age" | age-keygen -y > "$scratch/recovery.pub"
set export_status $pipestatus
test "$export_status[1]" -eq 0; and test "$export_status[2]" -eq 0; or exit 1
string match -qr '^age1pq1[0-9a-z]+$' < "$scratch/recovery.pub"; or exit 1
```

## Verify

Each decryption must independently print `recovery test`:

```fish
printf 'recovery test\n' | age -R "$scratch/mac.pub" -R "$scratch/recovery.pub" \
    -o "$scratch/test.age"; or exit 1
age -d -i "$key_dir/secure-enclave-pq.identity" "$scratch/test.age"; or exit 1
age -d -i "$key_dir/recovery-pq.age" "$scratch/test.age"; or exit 1
```

Copy `recovery-pq.age` to offline storage and repeat the second test using that
backup's path. Store the passphrase separately. Only then publish the recipients:

```fish
set mac (string lower (scutil --get LocalHostName)); or exit 1
test -n "$mac"; or exit 1
mkdir -p secrets/master-keys
cp "$scratch/mac.pub" "secrets/master-keys/$mac-pq.pub"
cp "$scratch/recovery.pub" secrets/master-keys/recovery.pub
rm -r "$scratch"
```

Commit only public recipients. Once the offline backup passes, the temporary
local encrypted recovery copy can be removed. No plaintext recovery key is saved.

For another Mac, enroll its enclave, copy the existing `recovery.pub` into the
scratch directory, and test using the offline recovery file. Publish only that
Mac's recipient. Run `just update-masterkeys`, then `just rekey` from an authorized
Mac to grant access to existing secrets. Do not generate another recovery key.

## Use and recover

Before declaring secrets, create the host identity once (replace `HOST`):

```fish
ssh root@HOST 'umask 077; mkdir -p /var/lib/agenix; age-keygen -pq -o /var/lib/agenix/key.txt'
mkdir -p secrets/public-keys
ssh root@HOST age-keygen -y /var/lib/agenix/key.txt > secrets/public-keys/HOST.pub
```

Commit the public key using the host's configured name. Use `just secret-edit`,
declare `age.secrets.<name>.rekeyFile`, then `just rekey`. Commit ciphertexts before
deploying. Hosts decrypt with their own age identity.

For recovery, open the tools shell and select the encrypted offline identity:

```fish
set -gx AGENIX_RECOVERY_IDENTITY /Volumes/BACKUP/recovery-pq.age
set -gx AGENIX_REKEY_PRIMARY_IDENTITY (string trim < secrets/master-keys/recovery.pub)
set -gx AGENIX_REKEY_PRIMARY_IDENTITY_ONLY true
```

Enroll the replacement Mac, run `just update-masterkeys` then `just rekey`, and
verify both decryptions. Exit the shell to clear the overrides.

#!/usr/bin/env fish

if test (id -u) -eq 0
    echo "Run ssh-setup as your normal user, without sudo." >&2
    exit 1
end
if not isatty stdin
    echo "Run ssh-setup in a terminal for passphrase prompts." >&2
    exit 1
end
umask 077

set key "$HOME/.ssh/id_ed25519"
mkdir -p "$HOME/.ssh"
or exit 1
if not test -e "$key"
    if test -e "$key.pub"; or test -L "$key"
        echo "An incomplete SSH key pair exists at $key; restore it before continuing." >&2
        exit 1
    end
    set email (git config --get user.email)
    or exit 1
    ssh-keygen -t ed25519 -f "$key" -C "$email"
    or exit 1
end
if not test -e "$key.pub"
    set public_key (ssh-keygen -y -f "$key")
    or exit 1
    printf '%s\n' "$public_key" >"$key.pub"
    or exit 1
end
set private_info (ssh-keygen -lf "$key")
or exit 1
set public_info (ssh-keygen -lf "$key.pub")
or exit 1
set private_fingerprint (string split -n ' ' -- "$private_info")[2]
set public_fingerprint (string split -n ' ' -- "$public_info")[2]
if test "$private_fingerprint" != "$public_fingerprint"
    echo "The SSH private and public keys do not match; restore the pair before continuing." >&2
    exit 1
end
# Apple's ssh-add stores the passphrase in the login Keychain.
/usr/bin/ssh-add --apple-use-keychain "$key"
or exit 1

echo "SSH key loaded using macOS Keychain integration."

#!/usr/bin/env fish

if test (id -u) -eq 0
    echo "Run github-setup as your normal user, without sudo." >&2
    exit 1
end
if not isatty stdin
    echo "Run github-setup in a terminal for browser login and passphrase prompts." >&2
    exit 1
end
if test -n "$GH_TOKEN"; or test -n "$GITHUB_TOKEN"
    echo "Unset GH_TOKEN and GITHUB_TOKEN to set up persistent GitHub credentials." >&2
    exit 1
end
set -gx GH_HOST github.com
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

set scopes admin:public_key,admin:ssh_signing_key
if not gh auth status --hostname github.com >/dev/null 2>&1
    gh auth login --hostname github.com --git-protocol ssh --web --skip-ssh-key --scopes "$scopes"
    or exit 1
end
gh config set git_protocol ssh --host github.com
or exit 1

read -l key_type key_data comment <"$key.pub"
or exit 1
set title (/usr/sbin/scutil --get LocalHostName)
or exit 1
for type in authentication signing
    set endpoint user/keys
    if test "$type" = signing
        set endpoint user/ssh_signing_keys
    end
    set registered (gh api --hostname github.com --paginate --slurp "$endpoint")
    or begin
        echo "Could not list GitHub $type keys. If permissions are missing, run:" >&2
        echo "  gh auth refresh --hostname github.com --scopes $scopes" >&2
        exit 1
    end
    if not printf '%s\n' $registered | jq -e --arg key "$key_type $key_data" \
            'any(.[][]; (.key | split(" ") | .[0:2] | join(" ")) == $key)' >/dev/null
        gh ssh-key add "$key.pub" --type "$type" --title "$title"
        or exit 1
    end
end
echo "GitHub authentication and commit signing are configured."

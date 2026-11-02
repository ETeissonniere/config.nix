# config.nix

My Macs, NixOS machines, and dotfiles, managed with
[Nix](https://nixos.org/), [nix-darwin](https://github.com/nix-darwin/nix-darwin),
[nh](https://github.com/nix-community/nh), and [deploy-rs](https://github.com/serokell/deploy-rs).
NixOS installation uses [nixos-anywhere](https://github.com/nix-community/nixos-anywhere)
and [disko](https://github.com/nix-community/disko).

## macOS setup

Install [Nix](https://nixos.org/download/) and Apple's command-line tools
(`xcode-select --install`), then open a new terminal. Choose a host from `hosts/`
and check its architecture, username, and UID (`id -u`).

For the first activation (replace `wintermute` with your host):

```sh
nix --extra-experimental-features 'nix-command flakes' shell --inputs-from . nixpkgs#just nixpkgs#nh
just host=wintermute check
just host=wintermute switch
exit
```

This installs `nh` and `just`; restart your terminal afterward.
Homebrew is managed automatically; activation
upgrades declared packages and removes unlisted packages and associated cask data.

Each Mac provisions a `default` key for SSH and Git signing.
Use `scauth pubkey default` to retrieve its public key
for your servers, and save it on GitHub as both an authentication and signing key.

Macs use the Darwin `workstation` profile for their apps and settings.
Each machine declares its secrets in `hosts/<host>/secrets.nix`.
Each host enables the features it uses: `workstation.nas.enable`,
`workstation.timeMachineOnNAS.enable`, `workstation.linuxBuilder.enable`, and
`workstation.nixRemoteBuilders.enable`. Time Machine on the NAS requires NAS
access. The local and remote builders can be enabled separately.

Set the local builder's CPU, memory, and disk size in the host's
`workstation.linuxBuilder` settings. `cores`, `memoryGiB`, and `diskGiB` default
to 6 cores, 6 GiB RAM, and a 64 GiB disk. Wintermute sets these values explicitly.

NAS mounts and Time Machine use the personal NAS account password in
`secrets/shared/personal-nas-password.age`. Before enabling Time Machine, add
`Eliott's Time Machine` on `nas.teiss.org` in System Settings > General >
Time Machine and turn on Encrypt Backups. macOS manages the backup encryption
password and each Mac's backup name; `tmutil` cannot enable encryption.

Each Mac uses its host-encrypted NAS password under `secrets/rekeyed/<host>/`.
After editing the shared password, run `just secrets-rekey` before switching.

## Usage

`host` defaults to this machine's hostname, lowercased (for example, `Wintermute`
becomes `wintermute`); override it before the recipe: `just host=wintermute check`.

| Command | Purpose |
| --- | --- |
| `just check [host]` | Evaluate a host; defaults to this machine |
| `just check-all` | Evaluate all Darwin and NixOS configurations |
| `just build [host]` | Build a host without applying; defaults to this machine |
| `just deploy [host]` | Deploy NixOS with deploy-rs |
| `just install [host] [user@address]` | Install NixOS; erases the host's configured disks |
| `just switch` | Build and apply this Mac's configuration with `nh` |
| `just update` | Update pinned dependencies without applying |
| `just format` | Format Nix files and recipes |

Run `just` to list recipes. Run `just check` and `just build` before switching.
Automatic Nix garbage collection runs weekly with 30-day retention. Keep
`stateVersion` values unchanged.

## Acknowledgments

[Anna's nixos-config](https://github.com/anna-oake/nixos-config) inspired the
host/module layout.

## Adding another Mac

Armitage uses the shared workstation profile with NAS, Time Machine, a local ARM
Linux builder, and Straylight for x86 Linux builds. The local VM keeps the default
6 virtual CPUs, 6 GiB RAM, and 64 GiB disk; 32 GB of host RAM does not require a
larger allocation. Configure its keys and backup before the first activation.
Missing enrollment files are errors; services are not silently disabled.

Create the `eliottteissonniere` admin account with UID 501, install Apple's
command-line tools and Nix, sign into the App Store, and transfer this checkout.
Do not copy private identities from another Mac or use the NixOS-only `just install`.

### Register keys before activation

On the new Mac, as the normal logged-in user, provision the same `default`
SSH/signing identity that Home Manager will later manage. This bootstrap config
is for a fresh user with no other scauth-managed identities:

```fish
nix --extra-experimental-features 'nix-command flakes' shell --inputs-from . nixpkgs#fish nixpkgs#just --command fish
sudo /usr/sbin/scutil --set LocalHostName armitage
sudo /usr/sbin/scutil --set ComputerName Armitage
set scauth_config (mktemp)
printf '%s\n' '{"user":"eliottteissonniere","identities":{"default":{"protection":"none"}}}' > "$scauth_config"
nix --extra-experimental-features 'nix-command flakes' run --inputs-from . scauth#default -- reconcile "$scauth_config"
rm "$scauth_config"

if not test -e /etc/nix/straylight_builder_ed25519
    sudo /usr/bin/ssh-keygen -t ed25519 -N '' -C armitage-builder -f /etc/nix/straylight_builder_ed25519
end

just mac-keys
```

`mac-keys` creates the post-quantum Secure Enclave age identity if absent and
exports its public recipient. Back up the identity file: recovery requires that
file and this Mac's hardware. Later activation adopts these existing SSH and
builder keys rather than generating replacements.

Enable Remote Login on Armitage for your account. Allow password authentication
or install Wintermute's public SSH key. Check Armitage's SSH host fingerprint on
Armitage before accepting it on Wintermute. From Wintermute:

```fish
just mac-enroll armitage eliottteissonniere@armitage.local
```

The first run prints any missing SSH key entries and stops. Paste those entries
into `modules/common/keys.nix`, then rerun the same command. Enrollment checks that the
catalog matches Armitage's keys before saving its age recipient and rekeying.
After it succeeds:

```fish
just check-all
just deploy chiba
just deploy straylight
```

Enrollment fetches only public keys, refuses an existing age recipient or
different catalog entries, and rekeys
`secrets/shared/personal-nas-password.age` for Armitage. It checks that the enrolled
configuration can read its ciphertext before reporting success. The source remains
encrypted for Wintermute and recovery; host ciphertext is under `secrets/rekeyed/`.
Review and commit the public keys and ciphertext, then transfer the updated
checkout to Armitage. The server deployments authorize its SSH and builder keys;
Armitage does not become a master identity for editing fleet secrets.

Public SSH keys are inline values in `modules/common/keys.nix`; private keys
stay on their owning machines.
GitHub separately receives each Mac's SSH/signing public key.

| Catalog entries | Purpose |
| --- | --- |
| `wintermute-ssh`, `armitage-ssh` | Let each Mac's user log into fleet machines |
| `wintermute-builder`, `armitage-builder` | Let each Mac's Nix daemon authenticate to Straylight |
| `straylight-host` | Let the Macs verify Straylight's SSH server identity before sending builds |

AGE public recipients remain in `secrets/recipients/`. They encrypt secrets for
each machine and are separate from SSH keys. Time Machine's backup encryption
password is managed in macOS, not stored or applied by this configuration.

### Activate the Mac

Before switching, configure a **new encrypted** backup in System Settings on
Armitage using `Eliott's Time Machine` on `nas.teiss.org`. Use the shared NAS
account password for SMB authentication. Create a separate backup; do not inherit
Wintermute's backup. macOS names it using this Mac's computer name. Choose and
retain the backup encryption password yourself; Nix does not generate, import,
or apply it. Give the activation terminal Full Disk Access.

The first build needs a working ARM Linux builder for uncached guest dependencies;
Armitage does not have its configured local VM yet. Builds on Wintermute can use
its builders. Copying those closures to Armitage requires trusted Nix signatures
or importing them as root; this repository does not grant that trust automatically.
Prepare these prerequisites before the first build.

Use the bootstrap shell from the macOS setup section with `host=armitage`: run
`check`, `build`, and `switch`, then restart the terminal. Register the SSH key
with GitHub using `fish scripts/postinstall/github-setup.fish`.

For later updates, transfer the updated checkout and run `just host=armitage switch`
on Armitage, or run that same command over interactive SSH from Wintermute:

```fish
ssh -t eliottteissonniere@armitage.local 'cd /path/to/config.nix && just host=armitage switch'
```

Replace `/path/to/config.nix` with the checkout location on Armitage. `nh` builds
on Armitage using its configured builders and prompts for sudo. Keep the Mac
logged into its desktop for Keychain and Secure Enclave approvals. For Time Machine
activation over SSH, enable Remote Login's “Allow full disk access for remote
users”; granting it to the local terminal does not authorize SSH. Otherwise,
activate locally. Mac updates
have no automatic connection-confirmation rollback; if needed, run
`sudo darwin-rebuild --rollback` on the Mac or over SSH while it is reachable.
Keep local access available for recovery. Disable Remote Login afterward if unused.
NixOS deployments continue to use `just deploy` and deploy-rs.

To update the SMB password, run `just secret shared/personal-nas-password` and
`just secrets-rekey` on Wintermute, then switch both Macs. This updates NAS
credentials, not backup encryption. Transfer local-only work separately:
Time Machine excludes `Developer` and `Downloads`.

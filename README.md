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

Armitage uses NAS, Time Machine, a local ARM Linux builder (6 virtual CPUs,
6 GiB RAM, 64 GiB disk), and Straylight for x86 Linux builds. Its 32 GB of RAM
does not require a larger VM allocation.

Create the `eliottteissonniere` admin account with UID 501, install Apple's
command-line tools and Nix, sign into the App Store, and transfer this checkout.
Provision and activate the Mac locally; Remote Login is not required.

### Create and register the keys

Run on Armitage as the normal logged-in user:

```fish
nix --extra-experimental-features 'nix-command flakes' shell --inputs-from . nixpkgs#fish nixpkgs#just nixpkgs#nh --command fish
sudo /usr/sbin/scutil --set LocalHostName armitage
sudo /usr/sbin/scutil --set ComputerName Armitage
just mac-keys armitage
```

`mac-keys` reuses Home Manager's scauth declaration to create the SSH/signing
identity, creates the builder key if absent, and creates the post-quantum Secure
Enclave age identity if absent. It does not activate the system. This key-only
step is needed because the full configuration requires registered public keys
and a NAS password encrypted for Armitage. Later activation reuses these identities.

Transfer only the printed public values to Wintermute:

- Add `armitage-ssh` and `armitage-builder` to `modules/common/keys.nix`.
- Save the printed age recipient as `secrets/recipients/armitage.pub`.

Keep private identities on Armitage. Back up its age identity file separately;
recovery requires that file and the same Mac's hardware. On Wintermute, run:

```fish
just secrets-rekey
just check-all
just deploy chiba
just deploy straylight
```

Review and commit the public keys and `secrets/rekeyed/armitage/` ciphertext,
then transfer the updated checkout back to Armitage. The Linux deployments
above authorize its SSH and builder keys; they do not provision the Mac.
Armitage does not become a master identity for editing fleet secrets.

Public SSH keys are inline in `modules/common/keys.nix`:

| Entries | Purpose |
| --- | --- |
| `wintermute-ssh`, `armitage-ssh` | User access to fleet machines and GitHub |
| `wintermute-builder`, `armitage-builder` | Each Mac's Nix daemon authenticating to Straylight |
| `straylight-host` | The Macs verifying Straylight's SSH server identity |

AGE public recipients remain in `secrets/recipients/`; private identities remain
outside the repository and Nix store.

### Activate locally

Before switching, configure a **new encrypted** backup in System Settings using
`Eliott's Time Machine` on `nas.teiss.org`. Use the shared NAS account password
for SMB authentication. Do not inherit Wintermute's backup. Choose and retain
the backup encryption password yourself; Nix does not manage it. Give the local
activation terminal Full Disk Access.

The first build needs a working ARM Linux builder for uncached guest dependencies;
Armitage does not have its configured local VM yet. Wintermute can prebuild with
its builders, but importing those closures requires trusted signatures or root.
The repository does not grant that trust automatically.

On Armitage, use the bootstrap shell above and run:

```fish
just host=armitage check
just host=armitage build
just host=armitage switch
```

Restart the terminal and run `fish scripts/postinstall/github-setup.fish` to
register the SSH/signing key with GitHub. For later updates, update the checkout
and run `just switch` locally. Use `sudo darwin-rebuild --rollback` locally if
needed. Keep `stateVersion` unchanged. Time Machine excludes `Developer` and
`Downloads`, so transfer that work separately.

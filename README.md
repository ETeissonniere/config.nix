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
Run `just setup-github` to sign in to GitHub and register it there for
authentication and signing. Run `just mac-keys` to print the keys a new Mac
adds to `lib/keys.nix` and `secrets/recipients/`.

Macs use the Darwin `workstation` profile for their apps and settings.
Each host enables the features it uses: `workstation.nas.enable`,
`workstation.timeMachineOnNAS.enable`, `workstation.linuxBuilder.enable`, and
`workstation.nixRemoteBuilders.enable`. Time Machine on the NAS requires NAS
access. The local and remote builders can be enabled separately.

Set the local builder's CPU, memory, and disk size in the host's
`workstation.linuxBuilder` settings. `cores`, `memoryGiB`, and `diskGiB` default
to 6 cores, 6 GiB RAM, and a 64 GiB disk.

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
| `just build [host]` | Build a host without applying; defaults to this machine |
| `just switch` | Build and apply this Mac's configuration with `nh` |
| `just deploy <host>` | Deploy a NixOS host with deploy-rs |
| `just update` | Update pinned dependencies without applying |
| `just secret <name>` | Edit `secrets/<name>.age`; follow with `just secrets-rekey` |

Run `just` to list every recipe. Run `just check` and `just build` before switching.
Automatic Nix garbage collection runs weekly with 30-day retention. Keep
`stateVersion` values unchanged.

## NixOS hosts

Each host declares its secrets in `hosts/<host>/secrets.nix` and decrypts them
with the age key at `/persist/agenix/<host>.key`; its public recipient lives in
`secrets/recipients/<host>.pub`. See `hosts/<host>/README.md` for the host itself.

- Straylight installs with `just install straylight <user@address>`. Disko
  reads the disk password from `/tmp/straylight-disk-password` on the target
  during installation only. Secure Boot keys live in `/var/lib/sbctl`.
- Chiba boots from an SD image:
  `nix build .#nixosConfigurations.chiba.config.system.build.sdImage`.

## Acknowledgments

[Anna's nixos-config](https://github.com/anna-oake/nixos-config) inspired the
host/module layout.

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

Host public keys live in `secrets/recipients/<host>.pub`; private identities stay
outside the repository. The shared secrets module uses each host's public key
when rekeying. Wintermute's identity currently manages the source secrets, with
recovery as another recipient. Adding another master requires re-encrypting the
existing source secrets for its public key as well as updating `masterIdentities`.

## Usage

`host` defaults to this machine's hostname, lowercased (for example, `Wintermute`
becomes `wintermute`); override it before the recipe: `just host=wintermute check`.

| Command | Purpose |
| --- | --- |
| `just check [host]` | Evaluate a host; defaults to this machine |
| `just check-all` | Evaluate all Darwin and NixOS configurations |
| `just build [host]` | Build a host without applying; defaults to this machine |
| `just deploy [host]` | Deploy NixOS updates with deploy-rs |
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

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

Each Mac provisions a `default` key for SSH and Git signing. Wintermute requires
Touch ID. Use `scauth pubkey default` to retrieve its public key
for your servers, and save it on GitHub as both an authentication and signing key.

## macOS post-install steps

After activation, connect to the NAS network and grant your terminal Full Disk
Access in System Settings → Privacy & Security. Run `just postinstall` without sudo.

On Wintermute, this also opens `smb://Eliott@nas.teiss.org/personal_folder` in Finder.
If prompted, enter the NAS password and save it in Keychain for future connections.
Run `just postinstall` again to reconnect after a restart; the share is not mounted
automatically at login.

This registers `nas.teiss.org` for Time Machine using a password prompt, excludes
`~/Developer` and `~/Downloads`, and enables backups. Configure backup encryption
or adoption of an older Mac's backups separately in macOS.

Existing backup destinations are preserved. The setup script runs only when
invoked, independently of Nix rebuilds.

Nix installs these apps; open each one after setup to configure it individually:

- **Stats:** Choose the metrics and widgets to show in the menu bar, and enable
  **Start at login**.
- **MonitorControl:** Configure display controls, enable its menu bar icon and
  **Start at login**, and grant Accessibility access when prompted for keyboard
  controls.
- **Logi Options+:** Complete onboarding, grant the requested macOS permissions,
  and configure Logitech devices, button mappings, and scrolling preferences.

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
| `just postinstall` | Connect Wintermute's NAS share and set up Time Machine |
| `just update` | Update pinned dependencies without applying |
| `just format` | Format Nix files and recipes |

Run `just` to list recipes. Run `just check` and `just build` before switching.
Automatic Nix garbage collection runs weekly with 30-day retention. Keep
`stateVersion` values unchanged.

## Acknowledgments

[Anna's nixos-config](https://github.com/anna-oake/nixos-config) inspired the
host/module layout.

# config.nix

My Macs and dotfiles, managed with Nix, nix-darwin, and [nh](https://github.com/nix-community/nh).

## Setup

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
Both wintermute and neutrino provision a Touch ID–protected `default` SSH identity
using [scauth.nix](https://github.com/ETeissonniere/scauth.nix). You may be prompted
to approve Touch ID during activation. Each Mac generates its own key, used for
SSH and Git signing. Existing SSH keys remain on disk, but are no longer selected
by this configuration. Register the new public key with your servers before using
it to connect; print it with `scauth pubkey default`.

Removing the identity from the configuration permanently deletes its managed key
on the next activation; a rollback cannot restore it.

Homebrew is managed automatically; activation
upgrades declared packages and removes unlisted packages and associated cask data.

## Post-install steps

After activation, connect to the NAS network and grant your terminal Full Disk
Access in System Settings → Privacy & Security. Run `just postinstall` without sudo:

1. **GitHub:** Signs into GitHub and registers the provisioned public key at
   `~/.ssh/scauth/default/id_ecdsa_sk.pub` for SSH authentication
   and commit signing. If scopes are missing, follow the printed refresh command.
2. **Time Machine:** Registers `nas.teiss.org` using a password prompt, excludes
   `~/Developer` and `~/Downloads`, and enables backups. Configure backup encryption
   or adoption of an older Mac's backups separately in macOS.

Existing keys and backup destinations are preserved. Credentials stay local;
check `gh auth status` for token storage, since Keychain failures can cause a
plaintext fallback. These scripts run only when invoked, independently of Nix
rebuilds. To run either step separately:

```sh
fish scripts/postinstall/github-setup.fish
fish scripts/postinstall/time-machine-setup.fish
```

Nix installs these apps; open each one after setup to configure it individually:

- **Stats:** Choose the metrics and widgets to show in the menu bar, and enable
  **Start at login**.
- **MonitorControl:** Configure display controls, enable its menu bar icon and
  **Start at login**, and grant Accessibility access when prompted for keyboard
  controls.
- **Logi Options+:** Complete onboarding, grant the requested macOS permissions,
  and configure Logitech devices, button mappings, and scrolling preferences.

## Usage

`host` defaults to the Mac's local hostname, lowercased (for example, `Neutrino`
becomes `neutrino`); override it before the recipe: `just host=wintermute check`.

| Command | Purpose |
| --- | --- |
| `just check` | Evaluate the configuration |
| `just check-all` | Evaluate all Darwin and NixOS configurations |
| `just build` | Build with `nh` without applying |
| `just switch` | Build and apply with `nh` |
| `just postinstall` | Set up SSH keys, GitHub, and Time Machine |
| `just update` | Update pinned dependencies without applying |
| `just format` | Format Nix files and recipes |

Run `just` to list recipes. Run `just check` and `just build` before switching.
Automatic Nix garbage collection runs weekly with 30-day retention. Keep
`stateVersion` values unchanged.

## Acknowledgments

[Anna's nixos-config](https://github.com/anna-oake/nixos-config) inspired the
host/module layout.

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
Homebrew is managed automatically; activation
upgrades declared packages and removes unlisted packages and associated cask data.

Each Mac provisions a `default` key for SSH and Git signing. Wintermute requires
Touch ID; neutrino does not. Use `scauth pubkey default` to retrieve its public key
for your servers, and save it on GitHub as both an authentication and signing key.

## Post-install steps

After activation, connect to the NAS network and grant your terminal Full Disk
Access in System Settings → Privacy & Security. Run `just postinstall` without sudo.

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

`host` defaults to the Mac's local hostname, lowercased (for example, `Neutrino`
becomes `neutrino`); override it before the recipe: `just host=wintermute check`.

| Command | Purpose |
| --- | --- |
| `just check` | Evaluate the configuration |
| `just check-all` | Evaluate all Darwin and NixOS configurations |
| `just build [host]` | Build the current machine or a named host without applying |
| `just switch` | Build and apply with `nh` |
| `just postinstall` | Set up Time Machine |
| `just update` | Update pinned dependencies without applying |
| `just format` | Format Nix files and recipes |

Run `just` to list recipes. Run `just check` and `just build` before switching.
Automatic Nix garbage collection runs weekly with 30-day retention. Keep
`stateVersion` values unchanged.

## Acknowledgments

[Anna's nixos-config](https://github.com/anna-oake/nixos-config) inspired the
host/module layout.

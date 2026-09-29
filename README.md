# config.nix

My Macs and dotfiles, managed with Nix, nix-darwin, and [nh](https://github.com/nix-community/nh).

## Setup

Install [Nix](https://nixos.org/download/) and Apple's command-line tools
(`xcode-select --install`), then open a new terminal. Choose a host from `hosts/`
and check its architecture, username, and UID (`id -u`).

For the first activation (replace `wintermute` with your host):

```sh
make check HOST=wintermute
nix --extra-experimental-features 'nix-command flakes' build 'path:.#darwinConfigurations.wintermute.system'
sudo ./result/sw/bin/darwin-rebuild switch --flake 'path:.#wintermute'
```

This installs `nh`; restart your terminal afterward.
Homebrew is managed automatically; activation
upgrades declared packages and removes unlisted packages and associated cask data.

## Post-install steps

After activation, connect to the NAS network and grant your terminal Full Disk
Access in System Settings → Privacy & Security. Run `make postinstall` without sudo:

1. **GitHub:** Generates `~/.ssh/id_ed25519` if missing, prompts for an optional
   passphrase, adds the key to Apple's SSH agent, and saves its passphrase in
   Keychain. Signs into GitHub and registers the public key for SSH authentication
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

`HOST` defaults to the Mac's local hostname, lowercased (for example, `Neutrino`
becomes `neutrino`); override it with `HOST=<name>`.

| Command | Purpose |
| --- | --- |
| `make check` | Evaluate the configuration |
| `make build` | Build with `nh` without applying |
| `make switch` | Build and apply with `nh` |
| `make postinstall` | Set up SSH keys, GitHub, and Time Machine |
| `nix flake update` | Update pinned dependencies without applying |
| `make fmt` | Format Nix files |

Run `make check` and `make build` before switching. Automatic Nix garbage
collection runs weekly with 30-day retention. Keep `stateVersion` values unchanged.

## Acknowledgments

[Anna's nixos-config](https://github.com/anna-oake/nixos-config) inspired the
host/module layout.

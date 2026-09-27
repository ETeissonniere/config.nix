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

## Usage

`HOST` defaults to `wintermute`; override it with `HOST=<name>`.

| Command | Purpose |
| --- | --- |
| `make check` | Evaluate the configuration |
| `make build` | Build with `nh` without applying |
| `make switch` | Build and apply with `nh` |
| `make update` | Update pinned dependencies without applying |
| `make fmt` | Format Nix files |
| `make clean` | Clean old generations with `nh` |

Run `make check` and `make build` before switching. Automatic Nix garbage
collection runs weekly with 30-day retention. Keep `stateVersion` values unchanged.

## Acknowledgments

[Anna's nixos-config](https://github.com/anna-oake/nixos-config) inspired the
host/module layout.

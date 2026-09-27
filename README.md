# config.nix

My machines and dotfiles, managed with Nix and nix-darwin (Mac hosts only).

## Setup

1. Install [Nix](https://nixos.org/download/) and Apple's command-line tools
   (`xcode-select --install`). Open a new terminal. Nix manages Homebrew's
   installation and taps, adopting an existing installation if present.
2. Choose a host from `hosts/`. Check its architecture, username, and UID
   (`id -u`) before applying it. Hosts and modules are discovered automatically.
   To add a Mac, copy a host directory, including its `users/` configuration.
   Shared identity lives in `modules/common/me.nix`. Choose
   `profiles.workstation.enable` for a desktop or `profiles.server.enable`
   for a server; only workstations get Ghostty.
3. Build, then apply from this repository:

   ```sh
   make check HOST=wintermute
   make build HOST=wintermute
   make switch HOST=wintermute
   ```

   `switch` requires sudo and configures the hostname, login shell, and dotfiles.
   Homebrew updates and upgrades declared packages on activation. Cleanup uses
   `zap`: unlisted packages and associated cask data are removed. Test in a VM
   until the package list is complete. Restart your terminal afterward.

## Usage

`HOST` defaults to `wintermute`; pass `HOST=<name>` for another configured Mac.

| Command | Purpose |
| --- | --- |
| `make check` | Evaluate the configuration |
| `make build` | Build without applying |
| `make switch` | Build and apply |
| `make update` | Update pinned dependencies |
| `make fmt` | Format Nix files |

After edits or updates, run `make check` and `make build` before switching.
Keep `stateVersion` values unchanged when updating packages.
`make update` refreshes all inputs in `flake.lock`, including the Homebrew taps;
`make switch` applies them. Ghostty's updater is disabled.

## Acknowledgments

[Anna's nixos-config](https://github.com/anna-oake/nixos-config) inspired the
host/module layout.

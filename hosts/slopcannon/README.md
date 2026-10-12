# slopcannon

Headless x86_64 NixOS coding VM on Proxmox. The VM advertises `slopcannon.local` through mDNS and runs
`codex remote-control` as a systemd service for remote access. Additionally, OpenSSH is configured and
accepting connections for `config.me.sshKeys`.

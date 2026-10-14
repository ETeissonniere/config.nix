# Straylight

Ryzen 9 9900X / RTX 4080 SUPER host, reachable at `straylight.local` via DHCP
and mDNS.

Straylight is the main lab compute server for remote gaming, experiments, and
isolated work and personal environments. It also serves as a remote Nix builder
for our Macs.

It has two SSDs, with the larger one holding AI models, Steam games, and other
data. Secure Boot uses our own keys, with TPM-backed disk decryption :smile:!

## Containers

We prefer native NixOS containers when possible, though also use Docker support
through `virtualisation.oci-containers` when needed. Manage both through systemd,
for example `sudo systemctl restart container@slopcannon`.

| Service | Purpose | Access and storage | Startup |
| --- | --- | --- | --- |
| `container@slopcannon` | Remote development in a native NixOS container. | Own LAN address and mDNS name: `ssh slopcannon.local`. Home, SSH host keys, and credentials persist under `/var/lib/nixos-containers/slopcannon`. | Automatic |
| `container@steam` | Remote gaming with [Steam Headless](https://github.com/Steam-Headless/docker-steam-headless), Sunshine, and NVIDIA GPU access. | Connect with Moonlight to Straylight. Persistent data lives under `/data/steam`. | Manual: `sudo systemctl start container@steam` |

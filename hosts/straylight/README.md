# Straylight

Ryzen 9 9900X / RTX 4080 SUPER host, reachable at `straylight.local` via DHCP
and mDNS.

Straylight is the main lab compute server for experiments and
isolated work and personal environments. It also serves as a remote Nix builder
for our Macs.

It has two SSDs, with the larger one holding AI models and other
data. Secure Boot uses our own keys, with TPM-backed disk decryption :smile:!

## Containers

Containers use native NixOS containers. Manage them through systemd, for example
`sudo systemctl restart container@slopcannon`.

| Service | Purpose | Access and storage | Startup |
| --- | --- | --- | --- |
| `container@slopcannon` | Remote development in a native NixOS container. | Own LAN address and mDNS name: `ssh slopcannon.local`. Home, SSH host keys, and credentials persist under `/data/slopcannon`. | Automatic |
| `container@slopkiddy` | Local AI: Open WebUI, llama.cpp, and ComfyUI behind Caddy, signed in through Pocket ID. | `openwebui.teiss.org` and `comfy.teiss.org`. State and manually downloaded models persist under `/data/slopkiddy`. | Automatic |

Slopcannon can run network tests of Firecracker microVMs. IPv4 forwarding is on,
tap links named `xsh0`, `xsh1`... may reach the container, and a test web server
on a network behind it answers at `192.0.2.1:8000` and `192.0.2.3:8000`. Sessions
hold no capability; run a command that creates links or nftables tables with
`with-net-admin <command>`, outside the agents' sandboxes.

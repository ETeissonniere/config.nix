# Straylight

Ryzen 9 9900X / RTX 4080 SUPER host, reachable at `straylight.local` via DHCP
and mDNS.

Straylight is the main lab compute server. It is used for a mix of remote play
and hosting a couple experiments or mini VMs/containers to isolate work and
personal projects. Because it runs Nix and SSH, we have also configured it as a
remote Nix builder for convenience.

We have two SSDs, with the bigger one set to hold AI models, Steam games, and so
on.

We run with Secure Boot on with our own keys, as well as TPM backed disk decryption :smile:.

## Remote development (`slopcannon`)

Slopcannon is a native NixOS container with private user and network namespaces.
Its home, SSH host keys, and credentials persist under
`/var/lib/nixos-containers/slopcannon`. It has its own LAN address and mDNS name;
connect with `ssh slopcannon.local`.

The container shares the host kernel and Nix store. Nix builds use the host
daemon as an untrusted client through remapped UIDs. The developer has no sudo
access, host Docker socket, host home, or forwarded SSH agent. Outbound network
access remains available.

On Straylight, use `sudo systemctl status container@slopcannon` or
`sudo systemctl restart container@slopcannon` to manage the container.

## Gaming

Gaming runs in a Steam Headless container with Sunshine. It stays off after boot
until started manually. On Straylight:

```fish
# Turn gaming on
gaming on

# Check its status
gaming status

# Turn gaming off (quit your game first)
gaming off
```

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

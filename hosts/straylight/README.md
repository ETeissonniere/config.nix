# Straylight

Ryzen 9 9900X / RTX 4080 SUPER host, reachable at `straylight.local` via DHCP
and mDNS.

Straylight is the main lab compute server. It is used for a mix of remote play
and hosting a couple experiments or mini VMs/containers to isolate work and
personal projects.

We have two SSDs, with the bigger one set to hold AI models, Steam games, and so
on.

We run with Secure Boot on with our own keys, as well as TPM backed disk decryption :smile:.

## Gaming

Gaming runs in a Steam Headless container with Sunshine. It stays off after boot
until started manually. Run these commands from your own computer:

```fish
# Turn gaming on
ssh straylight.local 'sudo systemctl start docker-steam'

# Check its status
ssh straylight.local 'systemctl status docker-steam --no-pager'

# Turn gaming off (quit your game first)
ssh straylight.local 'sudo systemctl stop docker-steam'
```

Stopping gaming stops Steam, Sunshine, and the container desktop. Games and
settings remain in `/data/steam`. The rest of the server keeps running.

### First-time setup

Start gaming, then open an SSH tunnel from your computer and leave it running
while using the setup interface:

```fish
ssh -N -L 8483:localhost:8483 straylight.local
```

1. Open <https://localhost:8483> for Steam Headless setup. Its local certificate
   is self-signed. The first-start service logs show the `steamheadless` account's
   temporary password; choose a permanent password in the setup interface.
2. Finish setup before pairing: Sunshine remains disabled until the permanent
   password is set. Use <https://localhost:8483/sunshine> to pair Moonlight with
   `straylight.local`. Start the Desktop stream to log in to Steam and launch
   games. The game library is under `/mnt/games/GameLibrary/Steam`.

This pinned image uses Steam Headless v2. The older `USER_PASSWORD` and
`SUNSHINE_PASS` environment file is no longer used. Authentication and driver
cache state persist in `/data/steam/state`, desktop settings in `/data/steam/home`,
and service journals in `/data/steam/journal`.

### Playing after setup

Turn gaming on and connect directly to `straylight.local` in Moonlight on the
same LAN. The SSH tunnel and browser desktop are only needed for setup or later
administration; they do not need to stay open while playing. Close the tunnel
with Ctrl+C when finished. New Moonlight clients need pairing through Sunshine.

For troubleshooting, view the service logs:

```fish
ssh straylight.local 'sudo journalctl -u docker-steam -n 100 --no-pager'
```

After a deployment that fixes a startup failure, clear the restart limit and
start the service again:

```fish
ssh straylight.local 'sudo systemctl reset-failed docker-steam; sudo systemctl start docker-steam'
```

Once initialization finishes, check the desktop, audio, input, and streaming
services inside the container:

```fish
ssh straylight.local 'sudo docker exec steam /usr/local/bin/steam-headless-healthcheck'
```

A successful Nix evaluation does not verify GPU encoding or streaming. Complete
setup, run the health check, and test a Moonlight session with video, audio, and
controller input before considering gaming ready.

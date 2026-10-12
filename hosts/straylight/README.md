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

On Straylight, create the private credentials file if it does not already exist:

```fish
sudo install -d -m 700 /data/steam
sudo touch /data/steam/environment
sudo chmod 600 /data/steam/environment
sudo nvim /data/steam/environment
```

Add these values, replacing the placeholders with your own passwords:

```dotenv
USER_PASSWORD=your-container-password
SUNSHINE_PASS=your-sunshine-password
```

Start gaming, then open an SSH tunnel from your computer and leave it running
during setup:

```fish
ssh -N -L 8083:localhost:8083 -L 47990:localhost:47990 straylight.local
```

1. Open <http://localhost:8083> for the container desktop, log in to Steam, and
   use `/mnt/games` for the Steam library.
2. Open <https://localhost:47990> for Sunshine administration. Its local
   certificate is self-signed. Log in as `admin` using `SUNSHINE_PASS`.
3. In Moonlight on your computer, add `straylight.local` and enter the pairing
   PIN in Sunshine. Start the Desktop stream to access Steam and launch games.

### Playing after setup

Turn gaming on and connect directly to `straylight.local` in Moonlight on the
same LAN. The SSH tunnel and browser desktop are only needed for setup or later
administration; they do not need to stay open while playing. Close the tunnel
with Ctrl+C when finished. New Moonlight clients need pairing through Sunshine.

For troubleshooting, view the service logs:

```fish
ssh straylight.local 'sudo journalctl -u docker-steam -n 100 --no-pager'
```

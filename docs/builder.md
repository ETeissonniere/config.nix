# Linux builder

Use a [prebuilt NixOS Proxmox LXC template](https://wiki.nixos.org/wiki/Proxmox_Linux_Container).
Choose an unused guest ID, storage, network, CPU, RAM and disk allocation.

## Prepare on the Mac

Create and export this Mac's admin and builder keys:

```fish
just switch
just export-ssh-keys
```

The `nix-builder` scauth identity uses the Secure Enclave without Touch ID.
A dedicated login-session SSH agent signs for the Nix daemon; remote builds
require this Mac's user to be logged in.

Review and commit the exported keys under `secrets/public-keys/ssh/`.
Send the admin keys to Proxmox:

```fish
nix eval --raw .#nixosConfigurations.lxc-builder.config.users.users.root.openssh.authorizedKeys.keys \
    --apply 'builtins.concatStringsSep "\n"' > /tmp/builder-admin.pub
scp /tmp/builder-admin.pub root@192.168.86.85:/tmp/builder-admin.pub
ssh root@192.168.86.85
```

## Create on Proxmox

Download the template onto Proxmox and replace the uppercase placeholders below.
`pct create` refuses occupied IDs; never use `--force`.

```sh
pct create VMID TEMPLATE --hostname lxc-builder --ostype nixos \
  --unprivileged 1 --features nesting=1 --rootfs STORAGE:DISK_GIB \
  --cores CORES --memory RAM_MIB --swap 0 --onboot 1 \
  --net0 name=eth0,bridge=BRIDGE,ip=IP_CIDR,gw=GATEWAY \
  --ssh-public-keys /tmp/builder-admin.pub &&
pct start VMID
```

Once the guest has booted, read its SSH fingerprint and return to the Mac:

```sh
pct exec VMID -- ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
exit
```

Verify that fingerprint when connecting from the Mac.

## Configure inside the container

Back on the Mac, replace `BUILDER_IP` with its address:

```fish
git archive HEAD | ssh root@BUILDER_IP 'mkdir -p /etc/nixos && tar -xf - -C /etc/nixos'
ssh root@BUILDER_IP
```

Inside the container:

```sh
export NIX_CONFIG='experimental-features = nix-command flakes'
nixos-rebuild switch --flake /etc/nixos#lxc-builder
exit
```

## Enable remote builds

The shared configuration enables remote builds for hosts with a public key in
`secrets/public-keys/ssh/builders/<hostname>.pub`. Deploy the exported key to the
builder, then apply the client configuration. Linux clients also need their Nix
daemon's SSH identity configured locally.

SSH selects the scauth identity for root connections as `builder`.
Run `just switch`, then verify access:

```fish
sudo ssh builder@BUILDER_IP true
```

Then run `just build lxc-builder`; Nix selects a compatible builder automatically.
The Mac SSH configuration maps `lxc-builder` to `192.168.86.23`; reserve that
address in the router.
Use `just deploy lxc-builder` for updates; deploy-rs handles activation and rollback.

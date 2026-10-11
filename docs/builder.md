# Linux builder

Use a [prebuilt NixOS Proxmox LXC template](https://wiki.nixos.org/wiki/Proxmox_Linux_Container).
Choose an unused guest ID, storage, network, CPU, RAM and disk allocation.

## Prepare on the Mac

Create and export this Mac's admin and builder keys:

```fish
just switch
just export-ssh-keys
```

Activation creates the root-owned key once and preserves it on subsequent runs.
The Nix daemon uses it directly, without an SSH agent or login session. Keep the private key outside Git. Linux clients use `/root/.ssh/nix-builder`.

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
builder, then apply the client configuration.

Run `just switch`, then verify access:

```fish
sudo ssh -F /dev/null -o IdentitiesOnly=yes -o IdentityAgent=none \
    -i /var/root/.ssh/nix-builder builder@lxc-builder.local true
```

Then run `just build lxc-builder`; Nix selects a compatible builder automatically.
Avahi advertises `lxc-builder.local` on the local network, so DHCP address changes
do not require client updates. Multicast DNS must be allowed between the machines.
SSH maps `lxc-builder` to this name; the builder's SSH host key remains pinned.
Use `just deploy lxc-builder` for updates; deploy-rs handles activation and rollback.

## Migrate from the scauth builder key

Run these in order, stopping on any error. The first deployment uses your unchanged
admin identity and builds on the server, so it does not require the old builder key.
Use the container's current IP for this first deployment (`192.168.86.25` below),
before it advertises its name. Verify the SSH fingerprint against Proxmox if prompted.

```fish
just switch
just export-ssh-keys
just check-all
nix run --inputs-from . deploy-rs -- "path:$PWD#lxc-builder" \
    --hostname 192.168.86.25 --remote-build --skip-checks
sudo ssh -F /dev/null -o IdentitiesOnly=yes -o IdentityAgent=none \
    -i /var/root/.ssh/nix-builder builder@lxc-builder.local true
just build lxc-builder
```

Switching creates the software key and removes the old builder agent and managed
scauth builder identity. Deployment replaces the server's authorized public key.
`--skip-checks` avoids pre-deployment builds through the key being replaced;
`just check-all` evaluates the configuration first. Normal deployments keep checks enabled.
Commit the exported public key after verification; never commit the private key.

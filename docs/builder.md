# Local Linux builder

Both Macs use nix-darwin's `linux-builder-vz`: an ARM Linux VM on Apple's
Virtualization.framework, with Rosetta for `x86_64-linux` builds. Requires Apple
silicon and macOS 13+. Activation installs Rosetta if missing, accepting Apple's
license, and manages the VM, SSH credentials and Nix builder registration.

## Migrate

Keep the Proxmox container until these checks pass. From this checkout:

```fish
just switch
sudo ssh linux-builder true
nix build --impure --no-link --rebuild --expr '
  let f = builtins.getFlake (toString ./.);
  in map (system: f.inputs.nixpkgs.legacyPackages.${system}.runCommand
    "local-builder-check"
    { preferLocalBuild = false; allowSubstitutes = false; }
    "uname -m > $out"
  ) [ "aarch64-linux" "x86_64-linux" ]'
```

The first boot can take a moment. Both builds must succeed through `linux-builder`.
Normal `nix build` commands then select it automatically. The default VM uses one
CPU and 3 GiB RAM; configuration lives in `modules/darwin/linux-builder.nix`.

## Remove the old builder

After verification, remove the old Mac key (repeat on any enrolled Mac):

```fish
sudo rm -f /var/root/.ssh/nix-builder /var/root/.ssh/nix-builder.pub
launchctl bootout gui/(id -u)/org.nixos.nix-builder-agent 2>/dev/null
rm -f ~/.ssh/scauth/builder-agent.sock
for host in lxc-builder lxc-builder.local 192.168.86.23 192.168.86.25
    ssh-keygen -R $host
    sudo ssh-keygen -R $host -f /var/root/.ssh/known_hosts
end
```

An absent old agent or known-hosts entry is harmless. Keep the new
`/etc/nix/builder_ed25519` credentials and `/var/lib/linux-builder` VM data.
Personal scauth and agenix identities are unrelated and must stay.

On **Proxmox**, inspect CT 100 and confirm it is `lxc-builder`. Copy out anything
you need: destruction deletes its disk, including the old host age identity.

```sh
pct config 100
pct shutdown 100 --timeout 60
pct status 100
# Only after it reports stopped and you have confirmed the container:
pct destroy 100 --purge 1
rm -f /tmp/builder-admin.pub
```

No router changes are needed. Container destruction removes its mDNS advertiser.

## Abandon secrets enrollment

No encrypted secrets were committed. If you encrypted anything elsewhere, recover
it before deleting identities. On each enrolled Mac:

```fish
rm -f ~/.config/agenix/secure-enclave-pq.identity ~/.config/agenix/recovery-pq.age
rm -f ~/.config/agenix/secure-enclave.identity ~/.config/agenix/yubikey.identity
rmdir ~/.config/agenix 2>/dev/null
set -e AGENIX_RECOVERY_IDENTITY AGENIX_REKEY_PRIMARY_IDENTITY AGENIX_REKEY_PRIMARY_IDENTITY_ONLY
```

Delete the offline `recovery-pq.age` backup and copies of these identity files too.
The age Secure Enclave identity is a device-bound file; it has no separate slot to
empty. This does not affect personal scauth identities. If the earlier YubiKey
PIV key still exists, identify its slot with `ykman piv info` before deleting that
specific key; do not reset the whole YubiKey.

{ inputs, lib, ... }:
{
  nix.sshServe = {
    enable = true;
    protocol = "ssh-ng";
    write = true;
    trusted = true;
    keys = lib.mapAttrsToList (_: mac: mac.builder) inputs.self.lib.keys.macs;
  };
}

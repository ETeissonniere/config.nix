{ inputs, lib, ... }:
{
  options.me.username = lib.mkOption {
    type = lib.types.str;
    default = "eliottteissonniere";
    description = "Primary user shared by all hosts.";
  };
  options.me.sshKeys = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = lib.mapAttrsToList (_: mac: mac.ssh) inputs.self.lib.keys.macs;
    description = "Public SSH keys trusted for the primary user.";
  };
}

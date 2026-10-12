{ lib, ... }:
{
  options.me.username = lib.mkOption {
    type = lib.types.str;
    default = "eliottteissonniere";
    description = "Primary user shared by all hosts.";
  };
  options.me.sshKeys = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ (lib.trim (builtins.readFile ./keys/wintermute.pub)) ];
    description = "Public SSH keys trusted for the primary user.";
  };
}

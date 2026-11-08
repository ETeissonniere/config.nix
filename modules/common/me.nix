{ lib, ... }:
let
  keys = import ./keys.nix;
in
{
  options.me.username = lib.mkOption {
    type = lib.types.str;
    default = "eliottteissonniere";
    description = "Primary user shared by all hosts.";
  };
  options.me.sshKeys = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [
      keys.wintermute-ssh
      keys.armitage-ssh
    ];
    description = "Public SSH keys trusted for the primary user.";
  };
}

{ lib, ... }:
let
  readKeys =
    directory:
    lib.mapAttrs'
      (name: _: {
        name = lib.removeSuffix ".pub" name;
        value = lib.trim (builtins.readFile (directory + "/${name}"));
      })
      (
        lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".pub" name) (
          if builtins.pathExists directory then builtins.readDir directory else { }
        )
      );
in
{
  options.me.username = lib.mkOption {
    type = lib.types.str;
    default = "eliottteissonniere";
    description = "Primary user shared by all hosts.";
  };
  options.me.sshKeys = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = readKeys ../../secrets/public-keys/ssh/admin;
    description = "Server administrative SSH public keys, named by device.";
  };
  options.me.builderKeys = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = readKeys (../.. + "/secrets/public-keys/ssh/builders");
    description = "Unattended Nix daemon SSH public keys, named by device.";
  };
}

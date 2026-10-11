{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.system.sshKeys;
  provision =
    keyConfig:
    let
      key = lib.escapeShellArg keyConfig.path;
      directory = lib.escapeShellArg (builtins.dirOf keyConfig.path);
      user = lib.escapeShellArg keyConfig.owner;
    in
    ''
      ${pkgs.coreutils}/bin/install -d -m 700 -o ${user} ${directory} || exit 1
      if [ ! -e ${key} ]; then
        (umask 077; ${pkgs.openssh}/bin/ssh-keygen -q -t ed25519 -N "" -f ${key}) || exit 1
      fi
      ${pkgs.coreutils}/bin/chown ${user} ${key} || exit 1
      ${pkgs.coreutils}/bin/chmod 600 ${key} || exit 1
      ssh_public_key=$(${pkgs.openssh}/bin/ssh-keygen -y -P "" -f ${key}) || exit 1
      printf '%s\n' "$ssh_public_key" > ${key}.pub || exit 1
      ${pkgs.coreutils}/bin/chown ${user} ${key}.pub || exit 1
    '';
in
{
  options.system.sshKeys = lib.mkOption {
    default = { };
    description = "Ed25519 SSH keys provisioned during activation, outside the Nix store.";
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          path = lib.mkOption {
            type = lib.types.strMatching "/.*";
            description = "Absolute runtime path of the private key; its public key uses the .pub suffix.";
          };
          owner = lib.mkOption {
            type = lib.types.str;
            default = "root";
            description = "Existing user that owns the key and its parent directory.";
          };
        };
      }
    );
  };

  config = lib.mkIf (cfg != { }) {
    system.activationScripts.${
      if pkgs.stdenv.hostPlatform.isDarwin then "postActivation" else "sshKeys"
    } =
    {
      text = lib.concatMapStringsSep "\n" provision (builtins.attrValues cfg);
    }
    // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux { deps = [ "users" ]; };
  };
}

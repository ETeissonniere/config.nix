{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.time-machine;
  destination = "smb://${lib.escapeURL cfg.username}@${cfg.host}/${lib.escapeURL cfg.share}";
in
{
  options.services.time-machine = {
    enable = lib.mkEnableOption "automatic Time Machine backups";

    host = lib.mkOption {
      type = lib.types.str;
      description = "Hostname of the SMB server. It must be reachable during initial setup.";
      example = "nas.local";
    };

    username = lib.mkOption {
      type = lib.types.str;
      description = "SMB account username, without URL encoding.";
    };

    share = lib.mkOption {
      type = lib.types.str;
      description = "SMB share name, without URL encoding.";
      example = "Time Machine";
    };

    passwordFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Absolute path to a runtime password file readable by root. Use a string
        path outside the Nix store; do not use a Nix path literal or readFile.
        One trailing newline is stripped. When null, tmutil prompts interactively.
        File-based setup passes the password in tmutil's URL argument, which may
        be visible to other processes. Interactive setup avoids this exposure.
        Credentials are only supplied when registering a new destination.
        Activation requires root and Full Disk Access.
      '';
    };

    exclusions = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Absolute paths to exclude from backups, even if they do not exist yet.
        Removing a path from this list does not remove its existing exclusion;
        use tmutil removeexclusion -p for that.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    system.activationScripts.postActivation.text = ''
      (
        set -e
        echo >&2 "Setting up Time Machine..."
        destination=${lib.escapeShellArg destination}
        if ! /usr/bin/tmutil destinationinfo | /usr/bin/awk '/^URL *: / { sub(/^URL *: /, ""); print }' | /usr/bin/grep -Fxq -- "$destination"; then
          ${if cfg.passwordFile == null then ''
            /usr/bin/tmutil setdestination -a -p "$destination"
          '' else ''
            # Read the secret only at activation time, never during Nix evaluation.
            set +x
            password=$(${lib.getExe pkgs.jq} -sRr 'rtrimstr("\n") | @uri' ${lib.escapeShellArg cfg.passwordFile})
            /usr/bin/tmutil setdestination -a ${lib.escapeShellArg "smb://${lib.escapeURL cfg.username}:"}"$password"${lib.escapeShellArg "@${cfg.host}/${lib.escapeURL cfg.share}"}
            unset password
          ''}
        fi
        ${lib.optionalString (cfg.exclusions != [ ]) ''
          /usr/bin/tmutil addexclusion -p ${lib.escapeShellArgs cfg.exclusions}
        ''}
        /usr/bin/tmutil enable
      )
    '';
  };
}

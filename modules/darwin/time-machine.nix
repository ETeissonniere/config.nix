{ config, lib, ... }:
let
  cfg = config.services.time-machine;
in
{
  options.services.time-machine = {
    enable = lib.mkEnableOption "automatic Time Machine backups";

    host = lib.mkOption {
      type = lib.types.str;
      description = "SMB server hostname, reserved for future automatic destination setup.";
      example = "nas.local";
    };

    username = lib.mkOption {
      type = lib.types.str;
      description = "SMB account username, reserved for future automatic destination setup.";
    };

    share = lib.mkOption {
      type = lib.types.str;
      description = "SMB share name, reserved for future automatic destination setup.";
      example = "Time Machine";
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
        ${lib.optionalString (cfg.exclusions != [ ]) ''
          /usr/bin/tmutil addexclusion -p ${lib.escapeShellArgs cfg.exclusions}
        ''}
        /usr/bin/tmutil enable
      )
    '';
  };
}

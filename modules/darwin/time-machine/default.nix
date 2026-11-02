# One-time setup on each new Mac, before activation:
# In System Settings > General > Time Machine, add the configured network share
# and enable Encrypt Backups. Save the encryption password securely; macOS owns
# the backup and its encryption credential in Keychain. Keep existing backups
# and their encryption settings unchanged.
# Give the activation terminal Full Disk Access. This module maintains the
# configured destination, SMB authentication, and exclusions; it neither creates
# encrypted backups nor verifies that the selected destination is encrypted.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.time-machine;
  destination = "smb://${lib.escapeURL cfg.account}@${cfg.server}/${lib.escapeURL cfg.share}";
  rawDestination = "smb://${cfg.account}@${cfg.server}/${cfg.share}";
  setup = pkgs.writeShellScript "time-machine-setup" ''
    set -euo pipefail
    export PATH=${lib.makeBinPath [ pkgs.jq ]}:/usr/bin:/bin
    state=/var/db/nix-time-machine
    destination=${lib.escapeShellArg destination}
    rawDestination=${lib.escapeShellArg rawDestination}
    revision=${lib.escapeShellArg cfg.credentialRevision}
    exclusions=(${lib.escapeShellArgs cfg.exclusions})
    registerDestination() {
      ${cfg.passwordCommand} |
        /usr/bin/expect -N -n ${../nas/password-prompt.exp} /usr/bin/tmutil setdestination -a -p "$destination"
    }
    ${builtins.readFile ./setup.sh}
  '';
in
{
  options.services.time-machine = {
    enable = lib.mkEnableOption "management of an existing Time Machine network destination";
    server = lib.mkOption { type = lib.types.str; };
    account = lib.mkOption { type = lib.types.str; };
    share = lib.mkOption { type = lib.types.str; };
    passwordCommand = lib.mkOption {
      type = lib.types.str;
      description = "Command that supplies the SMB authentication password on stdout at activation, not the backup encryption password.";
    };
    credentialRevision = lib.mkOption {
      type = lib.types.str;
      description = "Non-secret revision used to refresh credentials when the password changes.";
    };
    exclusions = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Paths excluded from backups. Removing a path here does not remove an existing exclusion.";
    };
  };
  config = lib.mkIf cfg.enable {
    system.activationScripts.postActivation.text = lib.mkOrder 950 ''
      echo >&2 "Configuring Time Machine..."
      ${setup} || exit 1
    '';
  };
}

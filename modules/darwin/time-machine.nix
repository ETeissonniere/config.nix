# tmutil cannot enable backup encryption. Before first activation, add this share
# in System Settings > General > Time Machine with Encrypt Backups enabled.
# macOS owns the encryption password; this module adopts the destination by URL
# without verifying encryption. The activation terminal needs Full Disk Access.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.time-machine;
  nas = config.services.nas;
  destination = "smb://${lib.escapeURL nas.account}@${nas.server}/${lib.escapeURL cfg.share}";
  rawDestination = "smb://${nas.account}@${nas.server}/${cfg.share}";
  setup = pkgs.writeShellScript "time-machine-setup" ''
    set -euo pipefail
    export PATH=${lib.makeBinPath [ pkgs.jq ]}:/usr/bin:/bin
    stateDir=/var/db/nix-time-machine
    destination=${lib.escapeShellArg destination}
    credentialRevision=${builtins.hashFile "sha256" nas.encryptedPasswordFile}

    if destinations=$(tmutil destinationinfo -X 2>&1); then
      destinations=$(printf '%s' "$destinations" | plutil -convert json -o - -- -)
    elif [ "$destinations" = "No destinations configured." ]; then
      destinations='{}'
    else
      echo >&2 "Cannot inspect Time Machine destinations; check Full Disk Access."
      exit 1
    fi
    if ! printf '%s' "$destinations" | jq -e \
        --arg url "$destination" --arg raw ${lib.escapeShellArg rawDestination} \
        'any(.Destinations[]?; .URL == $url or .URL == $raw)' >/dev/null; then
      echo >&2 "Configure this Time Machine destination and backup encryption in System Settings before switching."
      exit 1
    fi

    # Keep macOS's credentials on first adoption. Refresh them only after a
    # recorded SMB password revision changes.
    if [ -f "$stateDir/credential-revision" ] &&
        [ "$(cat "$stateDir/credential-revision")" != "$credentialRevision" ]; then
      ${nas.passwordCommand} |
        /usr/bin/expect -N -n ${./nas/password-prompt.exp} /usr/bin/tmutil setdestination -a -p "$destination"
    fi
    ${lib.optionalString (cfg.exclusions != [ ]) ''
      tmutil addexclusion -p ${lib.escapeShellArgs cfg.exclusions}
    ''}
    tmutil enable
    mkdir -p "$stateDir"
    printf '%s\n' "$credentialRevision" > "$stateDir/credential-revision"
  '';
in
{
  imports = [ ./nas ];

  options.services.time-machine = {
    enable = lib.mkEnableOption "management of an existing Time Machine destination on the configured NAS";
    share = lib.mkOption { type = lib.types.str; };
    exclusions = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Paths excluded from backups. Removing a path here does not remove an existing exclusion.";
    };
  };
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = nas.enable;
        message = "services.time-machine requires services.nas.enable.";
      }
    ];
    system.activationScripts.postActivation.text = lib.mkOrder 950 ''
      echo >&2 "Configuring Time Machine..."
      ${setup} || exit 1
    '';
  };
}

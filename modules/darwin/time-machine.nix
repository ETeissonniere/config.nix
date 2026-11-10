# tmutil cannot enable backup encryption. Before first activation, add this share
# in System Settings > General > Time Machine with Encrypt Backups enabled.
# macOS owns the credentials and encryption password. This module adopts the
# destination by URL without verifying encryption. The activation terminal needs
# Full Disk Access.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.time-machine;
  destination = "smb://${lib.escapeURL cfg.smbAccount}@${cfg.smbServerHost}/${lib.escapeURL cfg.smbShare}";
  setup = pkgs.writeShellScript "time-machine-setup" ''
    set -euo pipefail
    export PATH=${lib.makeBinPath [ pkgs.jq ]}:/usr/bin:/bin
    destination=${lib.escapeShellArg destination}

    if ! destinations=$(tmutil destinationinfo -X 2>&1); then
      echo >&2 "Cannot inspect Time Machine destinations; configure the backup in System Settings and grant the activation terminal Full Disk Access."
      exit 1
    fi
    if ! printf '%s' "$destinations" | plutil -convert json -o - -- - |
        jq -e --arg url "$destination" \
          '($url | @urid) as $target |
           any(.Destinations[]?; .URL == $target or (try (.URL | @urid) catch null) == $target)' >/dev/null; then
      echo >&2 "Configure this Time Machine destination and backup encryption in System Settings before switching."
      exit 1
    fi

    ${lib.optionalString (cfg.exclusions != [ ]) ''
      tmutil addexclusion -p ${lib.escapeShellArgs cfg.exclusions}
    ''}
    tmutil enable
  '';
in
{
  options.services.time-machine = {
    enable = lib.mkEnableOption "management of an existing Time Machine network destination";
    smbServerHost = lib.mkOption { type = lib.types.str; };
    smbAccount = lib.mkOption { type = lib.types.str; };
    smbShare = lib.mkOption { type = lib.types.str; };
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

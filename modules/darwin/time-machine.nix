# tmutil cannot enable backup encryption. Before first activation, add this share
# in System Settings > General > Time Machine with Encrypt Backups enabled.
# macOS owns the encryption password; this module adopts the destination by URL
# without verifying encryption. The activation terminal needs Full Disk Access.
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.time-machine;
  user = config.users.users.${config.system.primaryUser};
  destination = "smb://${lib.escapeURL cfg.smbAccount}@${cfg.smbServerHost}/${lib.escapeURL cfg.smbShare}";
  setup = pkgs.writeShellScript "time-machine-setup" ''
    set -euo pipefail
    export PATH=${lib.makeBinPath [ pkgs.jq ]}:/usr/bin:/bin
    stateDir=/var/db/nix-time-machine
    destination=${lib.escapeShellArg destination}
    credentialRevision=${builtins.hashFile "sha256" cfg.agePasswordFile}

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

    # On the first run, use the password already saved by macOS. On later runs,
    # update it only if the encrypted SMB password file has changed.
    if [ -f "$stateDir/credential-revision" ] &&
        [ "$(cat "$stateDir/credential-revision")" != "$credentialRevision" ]; then
      ${
        inputs.self.lib.darwin.decryptAgeSePassword {
          inherit pkgs user;
          inherit (cfg) agePasswordFile ageIdentityFile;
        }
      } |
        /usr/bin/expect -N -n ${./password-prompt.exp} /usr/bin/tmutil setdestination -a -p "$destination"
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
  options.services.time-machine = {
    enable = lib.mkEnableOption "management of an existing Time Machine network destination";
    smbServerHost = lib.mkOption { type = lib.types.str; };
    smbAccount = lib.mkOption { type = lib.types.str; };
    smbShare = lib.mkOption { type = lib.types.str; };
    agePasswordFile = lib.mkOption {
      type = lib.types.path;
      description = "AGE-encrypted SMB authentication password, decrypted at activation when credentials change.";
    };
    ageIdentityFile = lib.mkOption {
      type = lib.types.str;
      default = "${user.home}/.config/age/identity.key";
      description = "Runtime AGE identity belonging to the primary user.";
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

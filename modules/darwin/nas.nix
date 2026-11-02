{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.nas;
  user = config.users.users.${config.system.primaryUser};
  asUser = "/bin/launchctl asuser ${toString user.uid} /usr/bin/sudo -H -u ${lib.escapeShellArg user.name}";
  keychainArgs = lib.escapeShellArgs [
    "-s"
    cfg.smbServerHost
    "-a"
    cfg.smbAccount
    "-r"
    "smb "
  ];
  # Save the NAS password in the user's login Keychain so the login agent can
  # mount shares without asking for it again.
  installPassword = pkgs.writeShellScript "nas-install-password" ''
    set -euo pipefail
    export PATH=/usr/bin:/bin
    stateDir=${lib.escapeShellArg "${user.home}/Library/Application Support/nix-nas"}
    # Reuse the saved password if it is still in Keychain and this installer
    # hasn't changed. Updating the password file or allowed apps makes it run again.
    if [ "$(cat "$stateDir/credential-revision" 2>/dev/null || true)" = "$0" ] &&
        /usr/bin/security find-internet-password ${keychainArgs} >/dev/null 2>&1; then
      exit 0
    fi
    ${
      inputs.self.lib.darwin.decryptAgeSePassword {
        inherit pkgs user;
        inherit (cfg) agePasswordFile ageIdentityFile;
      }
    } |
      /usr/bin/expect -N -n ${./password-prompt.exp} /usr/bin/security add-internet-password \
        -U ${keychainArgs} -T "" \
        -T /System/Library/CoreServices/NetAuthAgent.app \
        -T /System/Library/CoreServices/Finder.app -w
    mkdir -p "$stateDir"
    printf '%s\n' "$0" > "$stateDir/credential-revision"
  '';
  # Run once at login to mount the configured NAS shares.
  mountShares = pkgs.writeShellScript "nas-mount" ''
    set -euo pipefail
    # Skip mounting if the NAS is unreachable or its password hasn't been saved.
    # Connect through Finder later when the NAS is available.
    /usr/bin/nc -z -G 3 ${lib.escapeShellArg cfg.smbServerHost} 445 >/dev/null 2>&1 || exit 0
    /usr/bin/security find-internet-password ${keychainArgs} >/dev/null 2>&1 || exit 0
    ${lib.concatMapStringsSep "\n" (share: ''
      /usr/bin/osascript -e 'on run arguments' -e 'mount volume (item 1 of arguments)' -e 'end run' \
        ${lib.escapeShellArg "smb://${lib.escapeURL cfg.smbAccount}@${cfg.smbServerHost}/${lib.escapeURL share}"}
    '') cfg.smbShares}
  '';
in
{
  options.services.nas = {
    enable = lib.mkEnableOption "NAS credentials and login mounts for the primary user";
    smbServerHost = lib.mkOption { type = lib.types.str; };
    smbAccount = lib.mkOption { type = lib.types.str; };
    smbShares = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "SMB shares to mount at login when the NAS is reachable.";
    };
    agePasswordFile = lib.mkOption {
      type = lib.types.path;
      description = "AGE-encrypted SMB password, decrypted into the primary user's login Keychain at activation.";
    };
    ageIdentityFile = lib.mkOption {
      type = lib.types.str;
      default = "${user.home}/.config/age/identity.key";
      description = "Runtime AGE identity belonging to the primary user.";
    };
  };
  config = lib.mkIf cfg.enable {
    system.activationScripts.postActivation.text = lib.mkOrder 900 ''
      echo >&2 "Installing NAS credentials..."
      ${asUser} ${installPassword} || exit 1
    '';
    launchd.user.agents.nas = lib.mkIf (cfg.smbShares != [ ]) {
      command = "${mountShares}";
      serviceConfig = {
        RunAtLoad = true;
        ProcessType = "Background";
      };
    };
  };
}

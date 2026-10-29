{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.nas;
  user = config.system.primaryUser;
  userHome = config.users.users.${user}.home;
  asUser = "/bin/launchctl asuser ${
    toString config.users.users.${user}.uid
  } /usr/bin/sudo -H -u ${lib.escapeShellArg user}";
  keychainArgs = lib.escapeShellArgs [
    "-s"
    cfg.server
    "-a"
    cfg.account
    "-r"
    "smb "
  ];
  decryptPassword = pkgs.writeShellScript "nas-decrypt-password" ''
    set -euo pipefail
    export PATH=${
      lib.makeBinPath [
        pkgs.age
        pkgs.age-plugin-se
      ]
    }:/usr/bin:/bin
    exec age --decrypt -i ${lib.escapeShellArg cfg.identityFile} ${lib.escapeShellArg cfg.encryptedPasswordFile}
  '';
  installPassword = pkgs.writeShellScript "nas-install-password" ''
    set -euo pipefail
    export PATH=/usr/bin:/bin
    state=${lib.escapeShellArg "${userHome}/Library/Application Support/nix-nas"}
    # The installer path changes with either the secret or the Keychain policy.
    if [ "$(cat "$state/credential-revision" 2>/dev/null || true)" = "$0" ] &&
        /usr/bin/security find-internet-password ${keychainArgs} >/dev/null 2>&1; then
      exit 0
    fi
    ${decryptPassword} |
      /usr/bin/expect -N -n ${./password-prompt.exp} /usr/bin/security add-internet-password \
        -U ${keychainArgs} -T "" \
        -T /System/Library/CoreServices/NetAuthAgent.app \
        -T /System/Library/CoreServices/Finder.app -w
    mkdir -p "$state"
    printf '%s\n' "$0" > "$state/credential-revision"
  '';
  mountShares = pkgs.writeShellScript "nas-mount" ''
    set -euo pipefail
    # Login can precede network availability. Leave offline mounts to Finder.
    /usr/bin/nc -z -G 3 ${lib.escapeShellArg cfg.server} 445 >/dev/null 2>&1 || exit 0
    /usr/bin/security find-internet-password ${keychainArgs} >/dev/null 2>&1 || exit 0
    ${lib.concatMapStringsSep "\n" (share: ''
      /usr/bin/osascript ${./mount.applescript} ${lib.escapeShellArg "smb://${lib.escapeURL cfg.account}@${cfg.server}/${lib.escapeURL share}"}
    '') cfg.shares}
  '';
in
{
  options.services.nas = {
    enable = lib.mkEnableOption "NAS credentials and login mounts for the primary user";
    server = lib.mkOption { type = lib.types.str; };
    account = lib.mkOption { type = lib.types.str; };
    shares = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "SMB shares to mount at login when the NAS is reachable.";
    };
    encryptedPasswordFile = lib.mkOption {
      type = lib.types.path;
      description = "AGE-encrypted NAS password, installed into the login Keychain on activation.";
    };
    identityFile = lib.mkOption {
      type = lib.types.str;
      default = "${userHome}/.config/age/identity.key";
      description = "Runtime AGE identity belonging to the primary user.";
    };
    passwordCommand = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      internal = true;
      description = "Decrypt the NAS password as the primary user; pipe stdout directly to a consumer.";
    };
  };
  config = lib.mkIf cfg.enable {
    # Do not trust the generic security CLI to export this Keychain item silently.
    # Rare Time Machine credential updates use the AGE identity's access controls.
    services.nas.passwordCommand = "${asUser} ${decryptPassword}";
    system.activationScripts.postActivation.text = lib.mkOrder 900 ''
      echo >&2 "Installing NAS credentials..."
      ${asUser} ${installPassword} || exit 1
    '';
    launchd.user.agents.nas = lib.mkIf (cfg.shares != [ ]) {
      command = "${mountShares}";
      serviceConfig = {
        RunAtLoad = true;
        ProcessType = "Background";
      };
    };
  };
}

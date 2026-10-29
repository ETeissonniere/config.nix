{ config, pkgs, ... }:
let
  mountPoint = "/mnt/nas-backups";
  stagingDirectory = "/persist/backup-staging/pocket-id";
  restartMarker = "/run/restic-backups-pocket-id/restart-pocket-id";
  systemctl = "${pkgs.systemd}/bin/systemctl";
in
{
  fileSystems.${mountPoint} = {
    # Use mDNS directly: the host deliberately resolves DNS independently of CoreDNS.
    device = "//gollum.local/personal_folder";
    fsType = "cifs";
    options = [
      "credentials=${config.age.secrets.nas-backup-creds.path}"
      "vers=3.1.1"
      "seal"
      "uid=0"
      "gid=0"
      "file_mode=0600"
      "dir_mode=0700"
      "nosuid"
      "nodev"
      "noexec"
      "_netdev"
      "nofail"
      "x-systemd.automount"
      "x-systemd.idle-timeout=5min"
      "x-systemd.mount-timeout=30s"
    ];
  };

  systemd.tmpfiles.rules = [ "d /persist/backup-staging 0700 root root -" ];

  services.restic.backups.pocket-id = {
    repository = "${mountPoint}/chiba/restic";
    passwordFile = config.age.secrets.restic-password.path;
    initialize = true;
    paths = [ stagingDirectory ];
    timerConfig = {
      OnCalendar = "*-*-* 03:00:00";
      RandomizedDelaySec = "15min";
      Persistent = true;
    };
    pruneOpts = [
      "--keep-daily 14"
      "--keep-weekly 8"
      "--keep-monthly 12"
    ];
    checkOpts = [ "--read-data" ];
    backupPrepareCommand = ''
      #!${pkgs.runtimeShell}
      set -euo pipefail
      ${pkgs.util-linux}/bin/findmnt --mountpoint ${mountPoint} --types cifs > /dev/null
      ${systemctl} is-active --quiet container@pocket-id.service
      rm -rf ${stagingDirectory}
      mkdir -m 0700 ${stagingDirectory}

      # Stage a consistent SQLite database and its files before uploading.
      touch ${restartMarker}
      ${systemctl} stop container@pocket-id.service
      cp -a /persist/pocket-id/var/lib/pocket-id/. ${stagingDirectory}/
      ${systemctl} start container@pocket-id.service
      rm ${restartMarker}
    '';
    backupCleanupCommand = ''
      #!${pkgs.runtimeShell}
      set -euo pipefail
      # ExecStopPost also runs if preparation fails or is interrupted.
      if [ -e ${restartMarker} ]; then
        ${systemctl} start container@pocket-id.service
        rm ${restartMarker}
      fi
      rm -rf ${stagingDirectory}
    '';
  };

  systemd.services.restic-backups-pocket-id = {
    unitConfig.RequiresMountsFor = [ mountPoint ];
    serviceConfig.UMask = "0077";
  };
}

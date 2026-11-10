{
  config,
  lib,
  options,
  pkgs,
  ...
}:
let
  cfg = config.services.nas-backups;
  mountPoint = "/mnt/nas-backups";
  backupRoot = "/persist/backup-staging";
  # Serialize local copies so overlapping jobs cannot resume a service during another copy.
  lock = ''
    exec 9<${backupRoot}
    ${pkgs.util-linux}/bin/flock 9
  '';
  resticJobs = options.services.restic.backups.type;
  jobModules = [
    (lib.mkAliasOptionModule [ "encryptionKeyFile" ] [ "passwordFile" ])
    {
      options.stopService = lib.mkOption {
        type = lib.types.nullOr lib.types.nonEmptyStr;
        default = null;
        description = "Service to stop while copying the job's paths, then restart before uploading.";
      };
    }
  ];
  stagedJobs = lib.filterAttrs (_: job: job.stopService != null) cfg.jobs;
  validSource =
    path:
    let
      source = /. + path;
      staging = /. + backupRoot;
    in
    lib.hasPrefix "/" path
    && lib.path.subpath.isValid (lib.removePrefix "/" path)
    && !(lib.path.hasPrefix source staging || lib.path.hasPrefix staging source);
in
{
  options.services.nas-backups = {
    nasShare = lib.mkOption {
      type = lib.types.nonEmptyStr;
      description = "SMB share where the host's restic repository is stored.";
      example = "//nas.local/backups";
    };
    nasCredentials = lib.mkOption {
      type = lib.types.externalPath;
      description = "Runtime path to a mount.cifs credentials file.";
    };
    jobs = lib.mkOption {
      type = resticJobs.substSubModules (resticJobs.getSubModules ++ jobModules);
      default = { };
      description = "NAS backup jobs, each configured with services.restic.backups options.";
    };
  };

  config = lib.mkIf (cfg.jobs != { }) {
    # mount.cifs resolves .local names through libc, which needs the Avahi NSS plugin.
    services.avahi = lib.mkIf (builtins.match "//[^/]+\\.local/.*" cfg.nasShare != null) {
      enable = true;
      nssmdns4 = true;
    };
    fileSystems.${mountPoint} = {
      device = cfg.nasShare;
      fsType = "cifs";
      options = [
        "credentials=${cfg.nasCredentials}"
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

    services.restic.backups = lib.mkMerge [
      (lib.mkAliasDefinitions options.services.nas-backups.jobs)
      (lib.mapAttrs (name: job: _: {
        imports = jobModules;
        # Restic sees the stable copy, while the host declares the actual source paths.
        options = lib.optionalAttrs (job.stopService != null) {
          paths = lib.mkOption { apply = _: [ "${backupRoot}/${name}" ]; };
        };
        config = {
          repository = lib.mkDefault "${mountPoint}/${config.networking.hostName}/restic";
          initialize = lib.mkDefault true;
          timerConfig = lib.mkDefault {
            OnCalendar = "*-*-* 03:00:00";
            RandomizedDelaySec = "15min";
            Persistent = true;
          };
          pruneOpts = lib.mkDefault [
            "--keep-daily 14"
            "--keep-weekly 8"
            "--keep-monthly 12"
          ];
          checkOpts = lib.mkDefault [ "--read-data" ];
        };
      }) cfg.jobs)
    ];
    systemd.tmpfiles.rules = lib.optional (stagedJobs != { }) "d ${backupRoot} 0700 root root -";
    assertions = lib.mapAttrsToList (name: job: {
      assertion =
        lib.path.subpath.isValid name
        && name != "."
        && !(lib.hasInfix "/" name)
        && job.paths != null
        && job.paths != [ ]
        && lib.all validSource job.paths;
      message = "NAS backup ${name} with stopService needs a plain job name and absolute source paths without traversal or overlap with ${backupRoot}.";
    }) stagedJobs;
    systemd.services = lib.mapAttrs' (
      name: job:
      let
        stage = lib.escapeShellArg "${backupRoot}/${name}";
        marker = ''"$RUNTIME_DIRECTORY/restart-service"'';
        systemctl = "${pkgs.systemd}/bin/systemctl";
        service = lib.escapeShellArg job.stopService;
        restart = ''
          ${systemctl} start -- ${service} && rm -- ${marker}
        '';
      in
      lib.nameValuePair "restic-backups-${name}" {
        unitConfig.RequiresMountsFor = [ mountPoint ];
        serviceConfig = {
          UMask = "0077";
          ExecStartPre = lib.mkBefore [
            "${pkgs.util-linux}/bin/findmnt --mountpoint ${mountPoint} --types cifs --output TARGET"
          ];
        };
        preStart = lib.mkIf (job.stopService != null) (
          lib.mkBefore ''
            (
              ${lock}
              ${systemctl} is-active --quiet -- ${service}
              rm -rf -- ${stage}
              mkdir -m 0700 -- ${stage}
              touch -- ${marker}
              resume() { ${restart} }
              trap 'resume || exit 1' EXIT
              ${systemctl} stop -- ${service}
              set -- ${lib.escapeShellArgs job.paths}
              if [ "$#" -eq 1 ] && [ -d "$1" ] && [ ! -L "$1" ]; then
                cp -a -- "$1/." ${stage}/
              else
                cp -a --parents -- "$@" ${stage}/
              fi
            )
          ''
        );
        # ExecStopPost also runs if stopping the service or copying its files failed.
        postStop = lib.mkIf (job.stopService != null) (
          lib.mkBefore ''
            if [ -e ${marker} ]; then
              (
                ${lock}
                ${restart}
              )
            fi
            rm -rf -- ${stage}
          ''
        );
      }
    ) cfg.jobs;
  };
}

{
  config,
  inputs,
  lib,
  ...
}:
let
  scratch = inputs.self.lib.scratch;
  scratchOnDisk = config.ephemeralRoot.scratchOnDisk;
in
{
  imports = [
    inputs.preservation.nixosModules.preservation
  ];

  options.ephemeralRoot.scratchOnDisk = lib.mkEnableOption "disk-backed /tmp and /var/tmp under /persist, emptied on each boot";

  config = {
    # Hosts supply persistent /nix and /persist mounts and their own state allowlist.
    fileSystems."/" = {
      device = "none";
      fsType = "tmpfs";
      # Cap transient data on / at 4GiB. Note that this is not reserving RAM, just saying we may grow **up to** 4GiB
      options = [
        "size=4G"
        "mode=755"
      ];
    };
    boot.tmp.useTmpfs = !scratchOnDisk;
    systemd.tmpfiles.rules = lib.mkIf scratchOnDisk scratch.wipeRules;
    fileSystems."/persist".neededForBoot = true;
    preservation = {
      enable = true;
      preserveAt."/persist" = {
        users.${config.me.username}.directories = [
          {
            # Fish replaces its history file atomically, so preserve the directory.
            directory = ".local/share/fish";
            mode = "0700";
          }
          {
            directory = ".cache";
            mode = "0700";
          }
        ];
        directories = [
          {
            directory = "/etc/ssh";
            inInitrd = true;
          }
          {
            directory = "/var/lib/nixos";
            inInitrd = true;
          }
          "/var/lib/systemd/timers"
          "/var/log"
        ]
        ++ lib.optionals scratchOnDisk (
          map (directory: {
            inherit directory;
            mode = "1777";
          }) scratch.directories
        );
        files = [
          {
            file = "/etc/machine-id";
            inInitrd = true;
          }
          {
            file = "/var/lib/systemd/random-seed";
            how = "symlink";
            inInitrd = true;
            configureParent = true;
          }
        ];
      };
    };
    # Preservation supplies the persistent machine ID before systemd starts.
    systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];
    users.mutableUsers = false;
  };
}

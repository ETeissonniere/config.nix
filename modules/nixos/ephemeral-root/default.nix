{
  config,
  inputs,
  ...
}:
{
  imports = [ inputs.preservation.nixosModules.preservation ];

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
  boot.initrd.systemd.enable = true;
  boot.tmp.useTmpfs = true;
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
      ];
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
}

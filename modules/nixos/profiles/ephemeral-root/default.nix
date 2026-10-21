{ inputs, ... }:
{
  imports = [ inputs.preservation.nixosModules.preservation ];

  # Hosts supply persistent /nix and /persist mounts and their own state allowlist.
  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
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
      directories = [
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

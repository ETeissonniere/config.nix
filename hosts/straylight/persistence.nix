{ lib, ... }:
{
  fileSystems."/nix" = {
    neededForBoot = true;
    depends = [ "/persist" ];
  };

  # Keep scratch space on disk, as in slopcannon, rather than in RAM.
  boot.tmp.useTmpfs = lib.mkForce false;
  # Empty it on each boot. systemd's tmp.conf still removes files older than
  # 10 days (/tmp) and 30 days (/var/tmp).
  systemd.tmpfiles.rules = [
    "D! /tmp 1777 root root"
    "D! /var/tmp 1777 root root"
  ];

  preservation.preserveAt."/persist".directories = [
    "/var/lib/sbctl"
    {
      directory = "/tmp";
      mode = "1777";
    }
    {
      directory = "/var/tmp";
      mode = "1777";
    }
  ];
}

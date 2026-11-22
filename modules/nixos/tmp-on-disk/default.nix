{
  # Equivalent to D! /tmp, like the /var/tmp rule below.
  boot.tmp.cleanOnBoot = true;
  systemd.tmpfiles.rules = [ "D! /var/tmp 1777 root root" ];
}

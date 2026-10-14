{ pkgs, ... }:
{
  # The Codex mobile client invokes /bin/bash directly for remote commands.
  systemd.tmpfiles.rules = [ "L+ /bin/bash - - - - ${pkgs.bash}/bin/bash" ];

  # Bubblewrap needs an unmasked proc mount to create nested PID namespaces.
  systemd.mounts = [
    {
      what = "proc";
      where = "/run/codex-proc";
      type = "proc";
      options = "nosuid,nodev,noexec";
      wantedBy = [ "local-fs.target" ];
      before = [ "systemd-user-sessions.service" ];
    }
  ];
}

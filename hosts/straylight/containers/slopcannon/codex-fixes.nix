{
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

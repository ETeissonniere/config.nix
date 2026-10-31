{ idleTimeout }:
{ pkgs, ... }:
{
  systemd.services.builder-idle-shutdown = {
    description = "Shut down the Linux builder when idle";
    serviceConfig.Type = "oneshot";
    environment.IDLE_TIMEOUT = toString idleTimeout;
    path = [
      pkgs.coreutils
      pkgs.iproute2
      pkgs.procps
      pkgs.gnugrep
      pkgs.systemd
    ];
    script = builtins.readFile ./idle-shutdown.sh;
  };
  systemd.timers.builder-idle-shutdown = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "1min";
      OnUnitActiveSec = "1min";
    };
  };
}

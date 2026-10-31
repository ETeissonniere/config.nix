{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.linux-builder;
  connect = pkgs.writeShellApplication {
    name = "linux-builder-connect";
    runtimeInputs = [ pkgs.openssh ];
    runtimeEnv.STARTUP_TIMEOUT = toString cfg.startupTimeout;
    text = builtins.readFile ./connect.sh;
  };
in
{
  options.services.linux-builder = {
    enable = lib.mkEnableOption "on-demand Linux builds with automatic idle shutdown";
    config = lib.mkOption {
      type = lib.types.deferredModule;
      default = { };
      description = "Host-specific NixOS configuration for the Linux builder.";
    };
    startupTimeout = lib.mkOption {
      type = lib.types.ints.positive;
      default = 120;
      description = "Seconds to wait for the builder's SSH service to become ready.";
    };
    idleTimeout = lib.mkOption {
      type = lib.types.ints.positive;
      default = 600;
      description = "Idle seconds before shutdown, checked once per minute. SSH connections and build processes keep the VM awake.";
    };
  };

  config = lib.mkIf cfg.enable {
    nix.linux-builder = {
      enable = true;
      config = { pkgs, ... }: {
        imports = [ cfg.config ];
        systemd.services.builder-idle-shutdown = {
          description = "Shut down the Linux builder when idle";
          serviceConfig.Type = "oneshot";
          environment.IDLE_TIMEOUT = toString cfg.idleTimeout;
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
      };
    };
    environment.etc."ssh/ssh_config.d/100-linux-builder.conf".text = lib.mkAfter ''
      ProxyCommand ${lib.getExe connect}
    '';
    launchd.daemons.linux-builder.serviceConfig = {
      RunAtLoad = lib.mkForce false;
      KeepAlive = lib.mkForce false;
    };
  };
}

{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.services.t3-remote-control.enable = lib.mkEnableOption "a loopback-only T3 Code server, for a reverse proxy to publish, through a Linux user service";

  config = lib.mkIf config.services.t3-remote-control.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.isLinux;
        message = "T3 Code remote control requires Linux.";
      }
    ];

    # `t3 pair` prints the pairing token other devices need.
    home.packages = [ pkgs.t3code ];

    systemd.user.services.t3-remote-control = {
      Unit.Description = "T3 Code server";
      Service = {
        # What `t3 service install` runs, minus the launcher that downloads and swaps in new t3 versions.
        # T3 Connect is left off so T3's relay cannot grant access to this machine. T3 only serves
        # plain HTTP, so other devices reach it through a TLS reverse proxy instead of --lan.
        ExecStart = "${pkgs.t3code}/bin/t3 serve --host 127.0.0.1";
        WorkingDirectory = "%h";
        Environment = [
          "PATH=%h/.local/bin:/run/wrappers/bin:/etc/profiles/per-user/${config.home.username}/bin:/run/current-system/sw/bin"
        ];
        KillMode = "mixed";
        Restart = "on-failure";
        RestartSec = 15;
        UMask = "0077";
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}

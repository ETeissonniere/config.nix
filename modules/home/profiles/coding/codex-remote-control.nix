{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.services.codex-remote-control.enable = lib.mkEnableOption "Codex remote control through a Linux user service";

  config = lib.mkIf config.services.codex-remote-control.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.isLinux;
        message = "Codex remote control requires Linux.";
      }
    ];

    systemd.user.services.codex-remote-control = {
      Unit.Description = "Codex remote control";
      Service = {
        # Wait for one-time login without repeatedly failing on a fresh installation.
        ExecCondition = "${pkgs.codex}/bin/codex login status";
        # The shared local socket lets `codex remote-control pair` reach this process.
        ExecStart = "${pkgs.codex}/bin/codex app-server --listen unix:// --remote-control --managed-daemon";
        WorkingDirectory = "%h";
        Environment = [
          "PATH=%h/.local/bin:/run/wrappers/bin:/etc/profiles/per-user/${config.home.username}/bin:/run/current-system/sw/bin"
        ];
        Restart = "on-failure";
        RestartSec = 15;
        UMask = "0077";
      };
      Install.WantedBy = [ "default.target" ];
    };

    systemd.user.paths.codex-remote-control = {
      Unit.Description = "Start Codex remote control after login";
      Path.PathChanged = "%h/.codex/auth.json";
      Install.WantedBy = [ "default.target" ];
    };
  };
}

{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.services.codex-remote-control.enable = lib.mkEnableOption "Codex remote control through a Linux user service";

  config = {
    assertions = [
      {
        assertion = !config.services.codex-remote-control.enable || pkgs.stdenv.hostPlatform.isLinux;
        message = "Codex remote control requires Linux.";
      }
    ];

    programs.codex = {
      enable = true;
      # Preserve settings written by Codex while applying shared defaults on activation.
      mutableSettings = true;
      settings = {
        approval_policy = lib.mkDefault "on-request";
        approvals_reviewer = lib.mkDefault "auto_review";
        sandbox_mode = lib.mkDefault "workspace-write";
      };
    };
    home.file = {
      ".codex/AGENTS.md".text =
        builtins.replaceStrings
          [ "@shellInstructions@\n" ]
          [
            (lib.optionalString config.programs.fish.enable ''
              ## Shell commands
              - This machine uses fish. When generating commands or scripts to be run manually and locally, prefer fish syntax unless otherwise specified.
              - When running commands yourself within the Codex sandbox, keep the default configured shell and syntax.

            '')
          ]
          (builtins.readFile ./AGENTS.md);
      ".agents/skills/eliott-style".source = ./skills/eliott-style;
    };

    systemd.user.services.codex-remote-control = lib.mkIf config.services.codex-remote-control.enable {
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

    systemd.user.paths.codex-remote-control = lib.mkIf config.services.codex-remote-control.enable {
      Unit.Description = "Start Codex remote control after login";
      Path.PathChanged = "%h/.codex/auth.json";
      Install.WantedBy = [ "default.target" ];
    };
  };
}

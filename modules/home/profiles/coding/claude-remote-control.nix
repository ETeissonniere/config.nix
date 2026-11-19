{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.services.claude-remote-control.enable = lib.mkEnableOption "Claude Code Remote Control through a Linux user service";

  config = lib.mkIf config.services.claude-remote-control.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.isLinux;
        message = "Claude Code Remote Control requires Linux.";
      }
    ];

    systemd.user.services.claude-remote-control = {
      Unit.Description = "Claude Code Remote Control";
      Service = {
        # Wait for one-time `claude auth login` without repeatedly failing on a fresh installation.
        ExecCondition = "${config.programs.claude-code.finalPackage}/bin/claude auth status";
        # Claude Code asks to enable Remote Control and to trust the folder on first run, and
        # has no setting for either; without a terminal those prompts block the service forever.
        ExecStartPre = pkgs.writeShellScript "claude-remote-control-accept-prompts" ''
          set -euo pipefail
          config="$HOME/.claude.json"
          [ -e "$config" ] || echo '{}' > "$config"
          ${lib.getExe pkgs.jq} --arg dir "$PWD" \
            '.remoteDialogSeen = true | .projects[$dir].hasTrustDialogAccepted = true' \
            "$config" > "$config.tmp"
          mv "$config.tmp" "$config"
        '';
        # An explicit spawn mode skips the interactive spawn-mode prompt for the same reason.
        ExecStart = "${config.programs.claude-code.finalPackage}/bin/claude remote-control --spawn=same-dir";
        WorkingDirectory = "%h/Developer";
        Environment = [
          "PATH=%h/.local/bin:/run/wrappers/bin:/etc/profiles/per-user/${config.home.username}/bin:/run/current-system/sw/bin"
        ];
        Restart = "on-failure";
        RestartSec = 15;
        UMask = "0077";
      };
      Install.WantedBy = [ "default.target" ];
    };

    systemd.user.paths.claude-remote-control = {
      Unit.Description = "Start Claude Code Remote Control after login";
      Path.PathChanged = "%h/.claude/.credentials.json";
      Install.WantedBy = [ "default.target" ];
    };
  };
}

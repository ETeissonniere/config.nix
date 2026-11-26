{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./t3-remote-control.nix
  ];

  config = {
    programs.claude-code = {
      enable = true;
      mutableSettings = true;
      settings.attribution = {
        commit = "";
        pr = "";
        sessionUrl = false;
      };
    };

    programs.codex = {
      enable = true;
      # Preserve settings written by Codex while applying shared defaults on activation.
      mutableSettings = true;
      settings = {
        approval_policy = lib.mkDefault "on-request";
        approvals_reviewer = lib.mkDefault "auto_review";
        commit_attribution = "";
        desktop.git-branch-prefix = "";
        sandbox_mode = lib.mkDefault "workspace-write";
      };
    };
    home.file = {
      ".agents/AGENTS.md".text =
        builtins.replaceStrings
          [ "@shellInstructions@\n" ]
          [
            (lib.optionalString config.programs.fish.enable ''
              ## Shell commands
              - This machine uses fish. When generating commands or scripts to be run manually and locally, prefer fish syntax unless otherwise specified.
              - When running commands yourself within the Codex sandbox, keep the default configured shell and syntax.

            '')
          ]
          (builtins.readFile ./agents/AGENTS.md);
      ".codex/AGENTS.md".source = config.home.file.".agents/AGENTS.md".source;
      ".claude/CLAUDE.md".source = config.home.file.".agents/AGENTS.md".source;
      ".agents/skills" = {
        source = ./agents/skills;
        recursive = true;
      };
      ".claude/skills".source =
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.agents/skills";
    };

    # Rex writes its skill and session hooks itself, so they follow Rex upgrades. Setup is
    # idempotent, and runs after the settings merges so they don't drop its hooks.
    home.activation.rexAgentSetup =
      lib.hm.dag.entryAfter [ "writeBoundary" "claudeCodeSettings" "codexMutableSettings" ]
        ''
          rex=${config.home.path}/bin/rex
          if [ -x "$rex" ]; then
            run --quiet "$rex" skill setup --autostart=false \
              || warnEcho "could not set up Rex's agent skill; the next switch will retry"
          fi
        '';
  };
}

{ config, lib, ... }:
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
      mutableSettings = true;
      settings = {
        approval_policy = lib.mkDefault "on-request";
        approvals_reviewer = lib.mkDefault "auto_review";
        commit_attribution = "";
        desktop.git-branch-prefix = "";
        sandbox_mode = lib.mkDefault "workspace-write";
      };
    };

    programs.antigravity-cli = {
      enable = true;
      mutableSettings = true;
      settings = {
        enableTerminalSandbox = lib.mkDefault true;
        toolPermission = lib.mkDefault "proceed-in-sandbox";
      };
    };

    home.file =
      let
        linkTo =
          source: paths:
          lib.genAttrs paths (_: {
            inherit source;
          });
      in
      {
        ".agents/skills" = {
          source = ./agents/skills;
          recursive = true;
        };
      }
      // linkTo ./agents/AGENTS.md [
        ".agents/AGENTS.md"
        ".codex/AGENTS.md"
        ".claude/CLAUDE.md"
        ".gemini/GEMINI.md"
      ]
      // linkTo (config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.agents/skills") [
        ".claude/skills"
        ".gemini/antigravity-cli/skills"
      ];
  };
}

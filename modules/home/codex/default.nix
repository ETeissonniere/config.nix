{ pkgs, ... }:
{
  home.packages = [ pkgs.codex ];
  home.file = {
    ".codex/AGENTS.md".source = ./AGENTS.md;
    ".agents/skills/eliott-style".source = ./skills/eliott-style;
  };
}

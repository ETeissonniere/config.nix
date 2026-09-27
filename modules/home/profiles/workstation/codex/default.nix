{ config, lib, ... }:
{
  config = lib.mkIf config.profiles.workstation.enable {
    home.file = {
      ".codex/AGENTS.md".source = ./AGENTS.md;
      ".agents/skills/eliott-style".source = ./skills/eliott-style;
    };
  };
}

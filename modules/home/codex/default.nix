{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.packages = [ pkgs.codex ];
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
}

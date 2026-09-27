{ ... }:
{
  programs.fish = {
    enable = true;
    functions.fish_greeting = "";
    shellInit = ''
      fish_add_path --prepend --path "$HOME/.local/bin"

      if type -q zed
        set -gx EDITOR 'zed --wait'
        set -gx VISUAL 'zed --wait'
      else
        set -gx EDITOR vim
        set -gx VISUAL vim
      end
    '';
    interactiveShellInit = ''
      bind ctrl-r history-pager
    '';
    shellAbbrs = {
      ls = "eza --icons=auto --hyperlink=auto";
      ll = "eza -lh --group-directories-first --icons=auto --hyperlink=auto";
      la = "eza -a --group-directories-first --icons=auto --hyperlink=auto";
    };
  };

  programs.eza = {
    enable = true;
    enableFishIntegration = false;
  };
  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
    options = [ "--cmd cd" ];
  };
}

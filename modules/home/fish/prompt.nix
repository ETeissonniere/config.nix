{ ... }:
{
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      add_newline = true;
      format = "$hostname$directory$git_branch$git_status$line_break$character";
      right_format = "$cmd_duration";
      directory = {
        style = "bold #73d0ff";
        truncation_length = 3;
        truncate_to_repo = true;
      };
      hostname = {
        ssh_only = true;
        format = "[$hostname](bold #f28779) ";
      };
      git_branch = {
        symbol = "git:";
        style = "#d5ff80";
        format = "[$symbol$branch]($style) ";
      };
      git_status.style = "#ffcc66";
      character = {
        success_symbol = "[❯](bold #d5ff80)";
        error_symbol = "[❯](bold #f28779)";
      };
      cmd_duration = {
        min_time = 2000;
        style = "#8a9199";
        format = "[took $duration]($style)";
      };
    };
  };
}

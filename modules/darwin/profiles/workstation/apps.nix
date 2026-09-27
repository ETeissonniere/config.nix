{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.profiles.workstation.enable {
    environment.systemPackages = [ pkgs.appcleaner ];

    homebrew.casks = [
      "bambu-studio"
      "chatgpt"
      "ghostty"
      "google-chrome"
      "logi-options+"
      "monitorcontrol"
      "orbstack"
      "stats"
    ];

    homebrew.masApps = {
      "Flighty" = 1358823008;
      "Keynote" = 361285480;
      "Numbers" = 361304891;
      "Pages" = 361309726;
      "Xcode" = 497799835;
    };
  };
}

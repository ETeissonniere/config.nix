{
  config,
  lib,
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    appcleaner
    chatgpt
    ghostty-bin
    google-chrome
    orbstack
    stats
  ];

  programs.mac-default-browser = {
    enable = true;
    browser = "chrome";
  };

  homebrew.casks = [
    "bambu-studio"
    "logi-options+"
    "monitorcontrol"
  ];

  homebrew.masApps = {
    "Flighty" = 1358823008;
    "Keynote" = 361285480;
    "Numbers" = 361304891;
    "Pages" = 361309726;
    "Xcode" = 497799835;
  };

  # postActivation runs after Homebrew has installed or upgraded Xcode.
  system.activationScripts.postActivation.text = lib.mkIf (config.homebrew.masApps ? Xcode) ''
    echo "Setting up Xcode..."
    if [ "$(/usr/bin/xcode-select --print-path)" != /Applications/Xcode.app/Contents/Developer ]; then
      /usr/bin/xcode-select --switch /Applications/Xcode.app/Contents/Developer
    fi

    if ! /Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -checkFirstLaunchStatus; then
      /Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -runFirstLaunch
    fi
  '';
}

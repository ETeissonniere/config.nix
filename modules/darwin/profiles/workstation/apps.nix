{
  config,
  lib,
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    appcleaner
    ghostty-bin
    google-chrome
    orbstack
    zed-editor
  ];

  home-manager.sharedModules = [
    (
      { config, lib, ... }:
      {
        programs.codex.settings.desktop.mac-menu-bar-enabled = false;

        home.activation.claudeMenuBar = lib.hm.dag.entryAfter [ "linkGeneration" ] (
          lib.hm.generators.mkImpureConfigMerger {
            inherit pkgs;
            format = "json";
            empty = "{}";
            path = "${config.home.homeDirectory}/Library/Application Support/Claude/claude_desktop_config.json";
            staticSettings = (pkgs.formats.json { }).generate "claude-desktop-preferences.json" {
              preferences.menuBarEnabled = false;
            };
            jqOperation = "$dynamic * $static";
            mode = "600";
          }
        );
      }
    )
    {
      programs.ghostty.package = null;
      programs.zed-editor.package = null;

      # Nix owns these apps; their built-in updaters cannot modify the store.
      targets.darwin.defaults = {
        "dev.kdrag0n.MacVirt" = {
          SUEnableAutomaticChecks = false;
          SUAutomaticallyUpdate = false;
        };
        "net.freemacsoft.AppCleaner" = {
          SUEnableAutomaticChecks = false;
          SUAutomaticallyUpdate = false;
        };
      };
    }
  ];

  programs.mac-default-browser = {
    enable = true;
    browser = "chrome";
  };

  homebrew.casks = [
    "bambu-studio"
    "chatgpt"
    "claude"
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

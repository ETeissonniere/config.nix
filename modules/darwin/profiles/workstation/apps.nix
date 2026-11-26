{
  config,
  lib,
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    container
    ghostty-bin
    zed-editor
  ];

  home-manager.sharedModules = [
    (
      { config, lib, ... }:
      {
        programs.codex.settings.desktop.mac-menu-bar-enabled = false;

        # GUI launches can lack NIX_SSL_CERT_FILE, which the nixpkgs wrapper uses for system roots.
        programs.claude-code.settings.env.CLAUDE_CODE_CERT_STORE = "bundled";

        # One more store path for this JSON exceeds Armitage's Darwin sandbox profile limit.
        home.activation.claudeMenuBar = lib.hm.dag.entryAfter [ "linkGeneration" ] (
          "("
          + lib.hm.generators.mkImpureConfigMerger {
            inherit pkgs;
            format = "json";
            empty = "{}";
            path = "${config.home.homeDirectory}/Library/Application Support/Claude/claude_desktop_config.json";
            staticSettings = "/dev/stdin";
            jqOperation = "$dynamic * $static";
            mode = "600";
          }
          + '') <<< '{"preferences":{"menuBarEnabled":false}}' ''
        );
      }
    )
    {
      programs.ghostty.package = null;
      programs.zed-editor.package = null;
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
    "google-chrome"
    "t3-code"
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

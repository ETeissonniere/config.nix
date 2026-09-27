{ config, inputs, ... }:
{
  imports = [
    inputs.self.commonModules.default
    inputs.nix-homebrew.darwinModules.nix-homebrew
  ];

  programs.fish.enable = true;

  nix-homebrew = {
    enable = true;
    autoMigrate = true;
    user = config.me.username;
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
    };
    mutableTaps = false;
  };

  homebrew = {
    enable = true;
    taps = builtins.attrNames config.nix-homebrew.taps;
    onActivation = {
      cleanup = "zap";
      autoUpdate = true;
      upgrade = true;
    };
  };

  home-manager = {
    backupFileExtension = "before-nix";
  };
}

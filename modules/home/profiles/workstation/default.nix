{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./fish
    ./ghostty.nix
    ./zed.nix
  ];

  config = lib.mkIf config.profiles.workstation.enable {
    programs.fish.enable = true;

    home.packages = with pkgs; [
      codex
      gh
      httpie
      jq
      python3Packages.huggingface-hub
      ripgrep
      vim
    ];

    programs.git = {
      enable = true;
      lfs.enable = true;
    };
  };
}

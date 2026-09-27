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

    home.activation.createDeveloperDirectory = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p ${lib.escapeShellArg "${config.home.homeDirectory}/Developer"}
    '';

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

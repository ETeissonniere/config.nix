{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../../codex
    ../../fish
    ../../ghostty.nix
    ../../git.nix
    ../../ssh.nix
    ../../zed.nix
  ];

  home.activation.createDeveloperDirectory = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p ${lib.escapeShellArg "${config.home.homeDirectory}/Developer"}
  '';

  home.packages = with pkgs; [
    gh
    httpie
    jq
    python3Packages.huggingface-hub
    ripgrep
    vim
  ];
}

{ inputs, pkgs, ... }:
{
  # for managing secrets in this repo
  home.packages = [
    pkgs.age
    inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  imports = [
    ../coding
    ./ghostty.nix
    ./zed.nix
  ];
}

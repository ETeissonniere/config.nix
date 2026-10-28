{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  # for managing secrets in this repo
  home.packages = [
    pkgs.age
    inputs.agenix-rekey.packages.${pkgs.stdenv.hostPlatform.system}.default
  ]
  ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [ pkgs.age-plugin-se ];

  imports = [
    ../coding
    ./ghostty.nix
    ./zed.nix
  ];
}

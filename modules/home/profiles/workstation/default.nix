{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./ghostty.nix
    ./zed.nix
    inputs.self.homeModules.profiles.coding
  ];

  # For managing secrets in this repo.
  home.packages = [
    pkgs.age
    inputs.agenix-rekey.packages.${pkgs.stdenv.hostPlatform.system}.default
  ]
  ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [ pkgs.age-plugin-se ];
}

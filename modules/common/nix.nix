{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.just
    pkgs.nh
  ];

  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.gc = {
    automatic = true;
    options = "--delete-older-than 30d";
  };
}

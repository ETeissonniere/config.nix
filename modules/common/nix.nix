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
  # cache.nixos.org skips unfree packages, so without this every nixpkgs bump
  # rebuilds the CUDA stack behind Straylight's PyTorch services from source.
  nix.settings.extra-substituters = [ "https://cache.nixos-cuda.org" ];
  nix.settings.extra-trusted-public-keys = [
    "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
  ];
  nix.gc = {
    automatic = true;
    options = "--delete-older-than 30d";
  };
}

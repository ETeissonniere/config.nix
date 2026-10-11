{ pkgs, ... }:
{
  imports = [ ./rosetta.nix ];

  nix.linux-builder = {
    enable = true;
    package = pkgs.darwin.linux-builder-vz;
    systems = [
      "aarch64-linux"
      "x86_64-linux"
    ];
    supportedFeatures = [
      "benchmark"
      "big-parallel"
    ];
  };
}

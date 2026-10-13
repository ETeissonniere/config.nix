{ pkgs, ... }:
{
  imports = [ ./rosetta.nix ];

  nix.linux-builder = {
    enable = true;
    ephemeral = false;
    maxJobs = 2;
    package = pkgs.darwin.linux-builder-vz;
    systems = [
      "aarch64-linux"
      "x86_64-linux"
    ];
    supportedFeatures = [
      "benchmark"
      "big-parallel"
    ];
    config = {
      virtualisation = {
        cores = 6;
        darwin-builder = {
          memorySize = 8 * 1024;
          diskSize = 40 * 1024;
        };
      };
      nix.gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 30d";
      };
    };
  };
}

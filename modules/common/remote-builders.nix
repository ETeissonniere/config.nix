{ config, lib, ... }:
{
  nix.distributedBuilds = lib.mkDefault (config.nix.buildMachines != [ ]);
  nix.settings.builders-use-substitutes = lib.mkIf config.nix.distributedBuilds true;
}

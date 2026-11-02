{ inputs, ... }:
{
  imports = [
    inputs.self.darwinModules.profiles.workstation
    inputs.self.darwinModules.linearmouse
    ./secrets.nix
  ];

  workstation = {
    nas.enable = true;
    timeMachineOnNAS.enable = true;
    linuxBuilder = {
      enable = true;
      cores = 6;
      memoryGiB = 6;
      diskGiB = 64;
    };
    nixRemoteBuilders.enable = true;
  };
  services.linearmouse.enable = true;
}

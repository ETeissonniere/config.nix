{ inputs, ... }:
{
  imports = [
    inputs.self.darwinModules.profiles.workstation
    ./secrets.nix
  ];

  workstation = {
    nas.enable = true;
    timeMachineOnNAS.enable = true;
    linuxBuilder.enable = true;
    nixRemoteBuilders.enable = true;
  };
}

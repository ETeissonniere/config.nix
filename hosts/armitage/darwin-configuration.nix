{ inputs, ... }:
{
  imports = [
    inputs.self.darwinModules.profiles.workstation
  ];

  workstation = {
    nas.enable = true;
    timeMachineOnNAS.enable = true;
    linuxBuilder.enable = true;
    nixRemoteBuilders.enable = true;
  };

  # Compatibility baseline for this installation; do not bump during updates.
  system.stateVersion = 6;
}

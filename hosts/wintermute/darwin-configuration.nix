{ inputs, ... }:
{
  imports = [
    inputs.self.darwinModules.profiles.workstation
    inputs.self.darwinModules.linearmouse
  ];

  workstation = {
    nas.enable = true;
    timeMachineOnNAS.enable = true;
    linuxBuilder.enable = true;
    nixRemoteBuilders.enable = true;
  };
  services.linearmouse.enable = true;

  # Wintermute is the only Mac with an external display to control.
  homebrew.casks = [ "monitorcontrol" ];

  # Compatibility baseline for this installation; do not bump during updates.
  system.stateVersion = 6;
}

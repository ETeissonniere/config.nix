{ inputs, ... }:
{
  imports = [
    inputs.self.darwinModules.profiles.workstation
    inputs.self.darwinModules.linearmouse
  ];

  workstation = {
    nas.enable = true;
    timeMachine.enable = true;
    linuxBuilder.enable = true;
    nixRemoteBuilders.enable = true;
  };
  services.linearmouse.enable = true;
}

{ inputs, ... }:
{
  imports = [
    inputs.self.darwinModules.profiles.workstation
    ./secrets.nix
  ];

  workstation = {
    # Enable after registering the keys and rekeying the NAS password.
    nas.enable = false;
    timeMachineOnNAS.enable = false;
    linuxBuilder.enable = true;
    nixRemoteBuilders.enable = true;
  };
}

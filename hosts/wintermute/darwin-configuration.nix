{
  config,
  inputs,
  hostName,
  lib,
  ...
}:
{
  imports = [
    inputs.self.darwinModules.base
    inputs.self.darwinModules.profiles.workstation
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";
  networking = {
    inherit hostName;
    computerName = lib.strings.toSentenceCase hostName;
    localHostName = hostName;
  };

  users.users.${config.me.username}.uid = 501;

  # Compatibility baseline for this installation; do not bump during updates.
  system.stateVersion = 6;
}

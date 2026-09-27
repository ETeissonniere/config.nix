{
  config,
  inputs,
  hostName,
  lib,
  ...
}:
{
  imports = [ inputs.self.darwinModules.default ];

  profiles.workstation.enable = true;

  services.time-machine = {
    enable = true;
    host = "nas.teiss.org";
    username = "Eliott";
    share = "Eliott's Time Machine";
    exclusions = [
      "${config.users.users.${config.me.username}.home}/Developer"
      "${config.users.users.${config.me.username}.home}/Downloads"
    ];
  };

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

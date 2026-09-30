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

  services.mac-wallpaper.image = lib.mkForce ../../assets/wallpaper-phenix.jpg;

  homebrew.casks = [
    "kicad"
    "linear"
  ];

  homebrew.masApps = {
    "Slack for Desktop" = 803453959;
    "Tailscale" = 1475387142;
  };

  system.defaults.dock.persistent-apps = [
    "/Applications/Slack.app"
    "/Applications/Linear.app"
  ];
}

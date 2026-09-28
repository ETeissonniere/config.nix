{ lib, ... }:
{
  imports = [ ../wintermute/darwin-configuration.nix ];

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

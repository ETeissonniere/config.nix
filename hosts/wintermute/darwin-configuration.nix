{
  config,
  inputs,
  hostName,
  lib,
  ...
}:
{
  imports = [
    inputs.self.darwinModules.profiles.workstation
    inputs.self.lib.commonModules.nix-builders
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";
  nix.linux-builder.enable = true; # For Raspberry Pi hosts.
  networking = {
    inherit hostName;
    computerName = lib.strings.toSentenceCase hostName;
    localHostName = hostName;
  };

  users.users.${config.me.username}.uid = 501;

  homebrew.casks = [
    "moonlight"
  ];

  system.defaults.CustomUserPreferences."com.moonlight-stream.Moonlight" = {
    fps = 120;
    bitrate = 60000; # Kbps
    autoadjustbitrate = false;
    vsync = true;
  };

  # Compatibility baseline for this installation; do not bump during updates.
  system.stateVersion = 6;
}

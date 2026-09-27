{ config, lib, ... }:
{
  options.profiles = {
    workstation.enable = lib.mkEnableOption "workstation configuration";
    server.enable = lib.mkEnableOption "server configuration";
  };

  config.assertions = [
    {
      assertion = !(config.profiles.workstation.enable && config.profiles.server.enable);
      message = "Choose either the workstation or server profile.";
    }
  ];
}

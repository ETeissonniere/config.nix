{ inputs, osConfig, lib, ... }:
{
  imports = [ inputs.self.commonModules.profiles ];

  profiles = {
    workstation.enable = lib.mkDefault osConfig.profiles.workstation.enable;
    server.enable = lib.mkDefault osConfig.profiles.server.enable;
  };
}

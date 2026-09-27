{ config, lib, ... }:
{
  config = lib.mkIf config.profiles.workstation.enable {
    homebrew.casks = [ "ghostty" ];
  };
}

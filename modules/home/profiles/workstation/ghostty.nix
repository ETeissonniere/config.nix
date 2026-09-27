{ config, lib, pkgs, ... }:
{
  programs.ghostty = lib.mkIf config.profiles.workstation.enable {
    enable = true;
    package = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin null;
    settings = {
      command = lib.getExe config.programs.fish.package;
      auto-update = "off";
      keybind = "shift+enter=text:\\x1b\\r";
      shell-integration-features = "sudo,ssh-terminfo,ssh-env";
    };
  };
}

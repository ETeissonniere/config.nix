{
  config,
  lib,
  ...
}:
{
  programs.ghostty = {
    enable = true;
    settings = {
      command = lib.mkDefault (lib.getExe config.programs.fish.package);
      auto-update = "off";
      keybind = "shift+enter=text:\\x1b\\r";
      shell-integration-features = "sudo,ssh-terminfo,ssh-env";
    };
  };
}

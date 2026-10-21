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
      theme = "Ayu Mirage";
      font-size = 14;
      background-opacity = 0.85;
      background-blur = 20;
      window-padding-x = 16;
      window-padding-y = 16;
      keybind = "shift+enter=text:\\x1b\\r";
      shell-integration-features = "sudo,ssh-terminfo,ssh-env";
    };
  };
}

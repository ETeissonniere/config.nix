{
  config,
  lib,
  ...
}:
{
  config = lib.mkIf config.profiles.workstation.enable {
    services.mac-wallpaper = {
      enable = true;
      image = ../../../../assets/wallpaper-italy.jpg;
    };
  };
}

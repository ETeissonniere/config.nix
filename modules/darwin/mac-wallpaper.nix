{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.mac-wallpaper;
in
{
  options.services.mac-wallpaper = {
    enable = lib.mkEnableOption "the macOS desktop wallpaper";

    image = lib.mkOption {
      type = lib.types.path;
      description = "Wallpaper image to apply to all displays for the primary user.";
    };
  };

  config = lib.mkIf cfg.enable {
    system.activationScripts.postActivation.text = ''
      echo >&2 "Setting up wallpaper..."
      /bin/launchctl asuser "$(id -u ${lib.escapeShellArg config.system.primaryUser})" \
        sudo -H -u ${lib.escapeShellArg config.system.primaryUser} \
        ${lib.getExe pkgs.desktoppr} ${lib.escapeShellArg "${cfg.image}"}
    '';
  };
}

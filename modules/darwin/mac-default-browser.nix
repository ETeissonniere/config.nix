{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.mac-default-browser;
in
{
  options.programs.mac-default-browser = {
    enable = lib.mkEnableOption "the macOS default browser";

    browser = lib.mkOption {
      type = lib.types.str;
      example = "chrome";
      description = ''
        Browser identifier reported by defaultbrowser. The browser must already
        be installed. macOS may request confirmation when changing the default.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    system.activationScripts.postActivation.text = ''
      /bin/launchctl asuser "$(id -u ${lib.escapeShellArg config.system.primaryUser})" \
        sudo -H -u ${lib.escapeShellArg config.system.primaryUser} \
        ${lib.getExe pkgs.defaultbrowser} ${lib.escapeShellArg cfg.browser}
    '';
  };
}

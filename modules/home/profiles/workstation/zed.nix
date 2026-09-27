{ config, lib, ... }:
{
  config = lib.mkIf config.profiles.workstation.enable {
    programs.zed-editor = {
      enable = true;
      defaultEditor = true;
      userSettings.telemetry = {
        diagnostics = false;
        metrics = false;
      };
      extensions = [
        "git-firefly"
        "nix"
        "toml"
      ];
    };
  };
}

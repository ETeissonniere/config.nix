{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.open-webui;
  json = pkgs.formats.json { };
  managedSettings = json.generate "open-webui-settings.json" cfg.managedSettings;
in
{
  options.services.open-webui.managedSettings = lib.mkOption {
    type = lib.types.attrsOf json.type;
    default = { };
    example = {
      "subagents.enable" = true;
    };
    description = "Flat Open WebUI configuration keys restored on each startup. Other saved preferences are retained. Do not put secrets here.";
  };

  config = lib.mkIf cfg.enable {
    services.open-webui.package = lib.mkDefault (
      pkgs.open-webui.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ./image-review.patch ];
      })
    );
    # A separate command runs after the upstream data migration, which exits early.
    systemd.services.open-webui.serviceConfig.ExecStartPre = lib.mkIf (cfg.managedSettings != { }) (
      lib.mkAfter [
        (pkgs.writeShellScript "open-webui-settings" ''
          install -m 600 ${managedSettings} ${lib.escapeShellArg "${config.systemd.services.open-webui.environment.DATA_DIR}/config.json"}
        '')
      ]
    );
  };
}

{ config, lib, ... }:
let
  cfg = config.services.linearmouose;
in
{
  options.services.linearmouose = {
    enable = lib.mkEnableOption "mouse configuration with LinearMouse";
  };

  config = lib.mkIf cfg.enable {
    homebrew.casks = [ "linearmouse" ];
    home-manager.sharedModules = [
      {
        xdg.configFile."linearmouse/linearmouse.json".text = builtins.toJSON {
          "$schema" = "https://schema.linearmouse.app/0.12.0";
          schemes = [
            {
              buttons = {
                gesture = {
                  actions = {
                    down = "appExpose";
                    left = "missionControl.spaceLeft";
                    right = "missionControl.spaceRight";
                    up = "missionControl";
                  };
                  enabled = true;
                  threshold = 50;
                  trigger = {
                    button = {
                      controlID = 195;
                      kind = "logitechControl";
                      productID = 45122;
                      serialNumber = "6919B5E8";
                    };
                    command = false;
                    control = false;
                    option = false;
                    shift = false;
                  };
                };
                mappings = [
                  {
                    outcomes = {
                      swipe = {
                        up = "missionControl";
                      };
                    };
                    trigger = {
                      input = {
                        button = 6;
                      };
                    };
                  }
                  {
                    outcomes = {
                      shortPress = "missionControl";
                    };
                    trigger = {
                      input = {
                        button = {
                          controlID = 195;
                          kind = "logitechControl";
                          productID = 45122;
                          serialNumber = "6919B5E8";
                        };
                      };
                    };
                  }
                  {
                    outcomes = {
                      shortPress = "missionControl";
                      swipe = {
                        left = "missionControl.spaceLeft";
                        right = "missionControl.spaceRight";
                      };
                    };
                    trigger = {
                      input = {
                        button = {
                          controlID = 416;
                          kind = "logitechControl";
                          productID = 45122;
                          serialNumber = "6919B5E8";
                        };
                      };
                    };
                  }
                ];
                universalBackForward = true;
              };
              "if" = {
                device = {
                  category = "mouse";
                  productID = "0xc548";
                  productName = "USB Receiver";
                  vendorID = "0x46d";
                };
              };
              logitech = {
                highResolutionWheel = true;
              };
              pointer = {
                hardwareDPI = 2600;
              };
              scrolling = {
                reverse = {
                  vertical = true;
                };
              };
            }
          ];
        };
      }
    ];
  };
}

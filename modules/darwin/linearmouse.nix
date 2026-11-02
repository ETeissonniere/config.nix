{
  config,
  lib,
  ...
}:
let
  cfg = config.services.linearmouse;
in
{
  options.services.linearmouse = {
    enable = lib.mkEnableOption "mouse configuration with LinearMouse";
  };

  config = lib.mkIf cfg.enable {
    homebrew.casks = [ "linearmouse" ];
    launchd.user.agents.linearmouse.serviceConfig = {
      ProgramArguments = [
        "/Applications/LinearMouse.app/Contents/MacOS/LinearMouse"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      ProcessType = "Interactive";
      ThrottleInterval = 5;
    };
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
            {
              "if" = {
                app = "com.apple.iCal";
                device = {
                  category = "mouse";
                  productID = "0xc548";
                  productName = "USB Receiver";
                  vendorID = "0x46d";
                };
              };
              scrolling.smoothed.horizontal = {
                enabled = true;
                speed = 20;
                # Preserve trackpad-style scroll phases for Calendar's horizontal navigation.
                bouncing = true;
              };
            }
          ];
        };
      }
    ];
  };
}

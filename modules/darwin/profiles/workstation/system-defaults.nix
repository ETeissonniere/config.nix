{
  config,
  lib,
  ...
}:
{
  config = lib.mkIf config.profiles.workstation.enable {
    system.defaults = {
      NSGlobalDomain = {
        AppleMeasurementUnits = "Centimeters";
        AppleMetricUnits = 1;
        AppleTemperatureUnit = "Celsius";
        AppleInterfaceStyle = "Dark";
        AppleInterfaceStyleSwitchesAutomatically = false;
        AppleShowScrollBars = "WhenScrolling";
        KeyRepeat = 2;
        InitialKeyRepeat = 30;
        "com.apple.trackpad.scaling" = 3.0;
      };

      ".GlobalPreferences"."com.apple.mouse.scaling" = 3.0;
      hitoolbox.AppleFnUsageType = "Start Dictation";
      iCal."first day of week" = "Monday";

      finder = {
        FXPreferredViewStyle = "clmv";
        ShowExternalHardDrivesOnDesktop = false;
        ShowHardDrivesOnDesktop = false;
        ShowMountedServersOnDesktop = false;
        ShowRemovableMediaOnDesktop = false;
        NewWindowTarget = "Home";
      };

      CustomUserPreferences = {
        NSGlobalDomain = {
          AppleLocale = "en_US@currency=usd";
          AppleFirstWeekday.gregorian = 2;
        };
        "com.apple.finder" = {
          ShowSidebar = true;
          ShowRecentTags = false;
        };
      };
    };

    # Cmd+Shift+S copies a screenshot selection to the clipboard.
    system.keyboard.symbolicHotkeys."31" = {
      characterCode = 115;
      keyCode = 1;
      modifiers = [
        "command"
        "shift"
      ];
    };
  };
}

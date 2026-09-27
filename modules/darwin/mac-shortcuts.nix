{
  config,
  lib,
  ...
}:
let
  cfg = config.system.keyboard.symbolicHotkeys;
  modifierFlags = {
    shift = 131072;
    control = 262144;
    option = 524288;
    command = 1048576;
  };
  shortcutPlist =
    shortcut:
    lib.generators.toPlist { escape = true; } {
      inherit (shortcut) enabled;
      value = {
        type = "standard";
        parameters = [
          shortcut.characterCode
          shortcut.keyCode
          (lib.foldl' (flags: name: builtins.bitOr flags modifierFlags.${name}) 0 shortcut.modifiers)
        ];
      };
    };
in
{
  options.system.keyboard.symbolicHotkeys = lib.mkOption {
    default = { };
    description = "macOS system shortcuts by symbolic hotkey ID. Unlisted shortcuts are preserved.";
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          enabled = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Whether this shortcut is enabled.";
          };
          characterCode = lib.mkOption {
            type = lib.types.ints.unsigned;
            default = 65535;
            description = "Character code, or 65535 for a non-character key.";
          };
          keyCode = lib.mkOption {
            type = lib.types.ints.unsigned;
            description = "macOS virtual key code.";
          };
          modifiers = lib.mkOption {
            type = lib.types.listOf (lib.types.enum (builtins.attrNames modifierFlags));
            default = [ ];
            description = "Modifier keys held with the shortcut.";
          };
        };
      }
    );
  };

  config = lib.mkIf (cfg != { }) {
    system.activationScripts.postActivation.text = lib.concatStringsSep "\n" (
      lib.mapAttrsToList (id: shortcut: ''
        /bin/launchctl asuser "$(id -u ${lib.escapeShellArg config.system.primaryUser})" \
          sudo -H -u ${lib.escapeShellArg config.system.primaryUser} \
          /usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys \
          -dict-add ${lib.escapeShellArg id} ${lib.escapeShellArg (shortcutPlist shortcut)}
      '') cfg
    );
  };
}

{
  config,
  lib,
  pkgs,
  ...
}:
let
  # There is no Homebrew cask, so install the app once, like a cask would.
  # Rex updates itself through Sparkle afterwards, so this pin only matters on a fresh Mac.
  rexDmg = pkgs.fetchurl {
    url = "https://blob.superlogical.com/public/rex-app/preview/Rex-0.1.0-2147.dmg";
    hash = "sha256-UNTcmw4ZQV4BKzZ+V4zeKx8m1GR1wQNAw8rC5Thh6/8=";
  };
in
{
  system.activationScripts.postActivation.text = ''
    if ! /bin/ls -d /Applications/Rex*.app >/dev/null 2>&1; then
      echo "Installing Rex..."
      rexMount="$(/usr/bin/mktemp -d)"
      /usr/bin/hdiutil attach -nobrowse -readonly -mountpoint "$rexMount" ${rexDmg} >/dev/null
      for app in "$rexMount"/*.app; do
        /usr/bin/ditto "$app" "/Applications/$(/usr/bin/basename "$app")"
        # Sparkle updates the app in place, which needs the user to own it.
        /usr/sbin/chown -R ${lib.escapeShellArg config.system.primaryUser}:staff "/Applications/$(/usr/bin/basename "$app")"
      done
      /usr/bin/hdiutil detach "$rexMount" >/dev/null
      /bin/rmdir "$rexMount"
    fi
  '';
}

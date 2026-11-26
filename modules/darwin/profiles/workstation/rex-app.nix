{ config, lib, ... }:
let
  appcast = "https://blob.superlogical.com/public/rex-app/preview/appcast.xml";
  app = "/Applications/Rex.app";
in
{
  home-manager.sharedModules = [
    {
      # The app bundles rex and its terminfo; only its init.lua comes from here.
      programs.rex = {
        enable = true;
        package = null;
        config = ''
          rex.host({ label = "slopcannon", endpoints = { "ssh://slopcannon.local" }, icon = "server" })
        '';
      };
    }
  ];

  # There is no Homebrew cask, so install the newest build once, like a cask would.
  # Rex then updates itself through Sparkle, so Nix never pins or replaces it.
  system.activationScripts.postActivation.text = ''
    if [ ! -e ${app} ]; then
      echo "Installing Rex..."
      (
        set -euo pipefail
        work="$(/usr/bin/mktemp -d)"
        trap '/usr/bin/hdiutil detach -quiet "$work/mnt" 2>/dev/null || true; /bin/rm -rf "$work"' EXIT
        url="$(/usr/bin/curl -fsSL ${appcast} | /usr/bin/xmllint --xpath 'string(/rss/channel/item[1]/enclosure/@url)' -)"
        /usr/bin/curl -fsSL -o "$work/Rex.dmg" "$url"
        /usr/bin/hdiutil attach -quiet -nobrowse -readonly -mountpoint "$work/mnt" "$work/Rex.dmg"
        /usr/bin/codesign --verify --deep --strict \
          -R='identifier "com.superlogical.rex" and anchor apple generic' "$work/mnt/Rex.app"
        /usr/bin/ditto "$work/mnt/Rex.app" ${app}
        # Sparkle updates the app in place, which needs the user to own it.
        /usr/sbin/chown -R ${lib.escapeShellArg config.system.primaryUser}:staff ${app}
      ) || echo "warning: could not install Rex; the next activation will retry" >&2
    fi
  '';
}

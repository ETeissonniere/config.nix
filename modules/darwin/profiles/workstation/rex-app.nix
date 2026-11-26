{ config, lib, ... }:
let
  appcast = "https://blob.superlogical.com/public/rex-app/preview/appcast.xml";
  app = "/Applications/Rex.app";
  rexCli = "${app}/Contents/Helpers/Server.rex/Contents/MacOS/rex";
in
{
  home-manager.sharedModules = [
    (
      { lib, pkgs, ... }:
      {
        # Stored in Rex's own host list rather than a managed init.lua, which stays hand-editable.
        home.activation.rexHosts = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          if [ -x ${rexCli} ] && ! ${rexCli} hosts list --json \
              | ${lib.getExe pkgs.jq} -e 'any(.hosts[]; .host.label == "slopcannon")' >/dev/null; then
            run ${rexCli} hosts add slopcannon ssh://slopcannon.local --icon server \
              || warnEcho "could not add slopcannon to Rex; the next switch will retry"
          fi
        '';
      }
    )
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

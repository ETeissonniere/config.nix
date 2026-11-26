{ inputs, lib, ... }:
let
  # rex-app.nix installs the app, which bundles rex.
  app = "/Applications/Rex.app";

  # Every NixOS host and container, by its mDNS name.
  machines = lib.concatMapAttrs (
    name: host:
    { ${name} = host.config; } // lib.mapAttrs (_: container: container.config) host.config.containers
  ) inputs.self.nixosConfigurations;

  servesRex =
    machine:
    lib.any (user: user.services.rex.enable or false) (
      lib.attrValues (machine.home-manager.users or { })
    );

  rexServers = lib.attrNames (lib.filterAttrs (_: servesRex) machines);
in
{
  home-manager.sharedModules = [
    (
      { lib, pkgs, ... }:
      let
        addRexHosts = pkgs.writeShellApplication {
          name = "add-rex-hosts";
          runtimeInputs = [ pkgs.jq ];
          text = ''
            rex="${app}/Contents/Helpers/Rex Server.rex/Contents/MacOS/rex"
            want=${lib.escapeShellArg (builtins.toJSON rexServers)}

            hosts="$("$rex" hosts list --json)"
            for label in $(jq -r --argjson want "$want" '$want - [.hosts[].host.label] | .[]' <<<"$hosts"); do
              "$rex" hosts add "$label" "ssh://$label.local" --icon server.rack
            done
            hosts="$("$rex" hosts list --json)"

            # The app's Remote Hosts page lists its own records, which copy server hosts by id,
            # and it only writes one when a host is added in the app.
            prefs="$(mktemp)"
            trap 'rm -f "$prefs"' EXIT
            /usr/bin/defaults export com.superlogical.rex "$prefs" 2>/dev/null || true
            records="$(/usr/libexec/PlistBuddy -c 'Print :RexSync.servers' "$prefs" 2>/dev/null \
              || echo '{"formatVersion":1,"records":[]}')"
            updated="$(jq -c --argjson hosts "$hosts" --argjson want "$want" '
              (.records | map(.name)) as $names
              | .records += [
                  $hosts.hosts[].host
                  | select(.label as $label | ($want | index($label)) and (($names | index($label)) | not))
                  | { icon, id: (.id | ltrimstr("host:") | ascii_upcase), locators: .endpoints, name: .label }
                ]' <<<"$records")"
            if [ "$updated" != "$(jq -c . <<<"$records")" ]; then
              /usr/bin/defaults write com.superlogical.rex RexSync.servers \
                -data "$(printf %s "$updated" | /usr/bin/xxd -p | tr -d '\n')"
            fi
          '';
        };
      in
      {
        # Stored in Rex's own lists rather than a managed init.lua, which stays hand-editable.
        home.activation.rexHosts = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          if [ -e ${app} ]; then
            run ${lib.getExe addRexHosts} || warnEcho "could not add hosts to Rex; the next switch will retry"
          fi
        '';
      }
    )
  ];
}

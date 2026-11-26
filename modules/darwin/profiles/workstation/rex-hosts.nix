{ inputs, lib, ... }:
let
  # The app bundles rex; rex-app.nix installs it.
  rexCli = "/Applications/Rex.app/Contents/Helpers/Server.rex/Contents/MacOS/rex";

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
      {
        # Stored in Rex's own host list rather than a managed init.lua, which stays hand-editable.
        home.activation.rexHosts = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          if [ -x ${rexCli} ]; then
            if missing="$(${rexCli} hosts list --json | ${lib.getExe pkgs.jq} -r \
                --argjson want ${lib.escapeShellArg (builtins.toJSON rexServers)} \
                '$want - [.hosts[].host.label] | .[]')"; then
              for host in $missing; do
                run ${rexCli} hosts add "$host" "ssh://$host.local" --icon server \
                  || warnEcho "could not add $host to Rex; the next switch will retry"
              done
            else
              warnEcho "could not read Rex's hosts; the next switch will retry"
            fi
          fi
        '';
      }
    )
  ];
}

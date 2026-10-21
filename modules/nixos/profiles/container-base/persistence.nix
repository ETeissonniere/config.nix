{
  config,
  lib,
  pkgs,
  ...
}:
let
  # nspawn word-splits bind flags; tmpfiles also interprets whitespace and '%'.
  persistencePathType = lib.types.addCheck (lib.types.strMatching "/[A-Za-z0-9._+@/-]+") (
    path:
    let
      components = lib.tail (lib.splitString "/" path);
    in
    lib.all (component: component != "" && component != "." && component != "..") components
  );
  containersWithPersistence = lib.filterAttrs (
    _: container: container.persistence.directory != null
  ) config.containers;
in
{
  options.containers = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { config, ... }:
        let
          persistence = config.persistence;
        in
        {
          options.persistence = {
            directory = lib.mkOption {
              type = lib.types.nullOr persistencePathType;
              default = null;
              description = "Host directory for persistent state; null disables persistence.";
            };
            directories = lib.mkOption {
              type = lib.types.listOf persistencePathType;
              default = [ ];
              description = "Absolute container directories to preserve beneath the backing directory.";
            };
          };

          config.extraFlags = lib.mkIf (persistence.directory != null) (
            map (
              directory:
              # ID mapping keeps ownership independent of privateUsers=pick.
              "--bind=${persistence.directory}${directory}:${directory}"
              + lib.optionalString (config.privateUsers != "no") ":idmap"
            ) (persistence.directories ++ [ "/etc/machine-id" ])
          );
        }
      )
    );
  };

  config = lib.mkIf config.boot.enableContainers {
    assertions = lib.mapAttrsToList (name: container: {
      assertion = container.ephemeral;
      message = "containers.${name}.persistence requires ephemeral = true.";
    }) containersWithPersistence;

    systemd.tmpfiles.rules = lib.concatMap (
      container:
      let
        stateDirectory = container.persistence.directory;
      in
      [
        "d ${stateDirectory} 0700 root root -"
        "d ${stateDirectory}/etc 0755 root root -"
      ]
      ++ map (
        directory: "d ${stateDirectory}${directory} 0755 root root -"
      ) container.persistence.directories
    ) (builtins.attrValues containersWithPersistence);

    systemd.services = lib.mapAttrs' (
      name: container:
      let
        stateDirectory = container.persistence.directory;
      in
      lib.nameValuePair "container@${name}" {
        unitConfig.RequiresMountsFor = [ stateDirectory ];
        # nspawn needs the persistent identity before the container's systemd starts.
        preStart = lib.mkBefore ''
          if [ ! -s ${stateDirectory}/etc/machine-id ]; then
            ${pkgs.systemd}/bin/systemd-id128 new > ${stateDirectory}/etc/machine-id
          fi
        '';
      }
    ) containersWithPersistence;
  };
}

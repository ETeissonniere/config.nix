{ config, lib, ... }:
{
  options.containers = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.limits = {
          MemoryMax = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Maximum memory usage for the container, in systemd size notation.";
          };
          CPUQuota = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Maximum CPU time for the container, as a percentage of one CPU.";
          };
          TasksMax = lib.mkOption {
            type = lib.types.nullOr lib.types.ints.positive;
            default = null;
            description = "Maximum number of tasks in the container.";
          };
        };
      }
    );
  };

  config = lib.mkIf config.boot.enableContainers {
    systemd.services = lib.mapAttrs' (
      name: container:
      lib.nameValuePair "container@${name}" {
        serviceConfig = lib.filterAttrs (_: value: value != null) container.limits;
      }
    ) config.containers;
  };
}

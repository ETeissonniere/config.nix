{ config, lib, ... }:
let
  cfg = config.services.llama-swap;
  stateDirectory = cfg.stateDirectory;
  dataDir = "/var/lib/${stateDirectory}";
in
{
  options.services.llama-swap.stateDirectory = lib.mkOption {
    type = lib.types.str;
    default = "llama-swap";
    description = "Directory under /var/lib for inference runtime state and caches.";
  };

  config = lib.mkIf cfg.enable {
    systemd.services.llama-swap = {
      environment = {
        HOME = dataDir;
        XDG_CACHE_HOME = lib.mkForce "${dataDir}/cache";
        LD_LIBRARY_PATH = "/run/opengl-driver/lib";
      };
      serviceConfig = {
        StateDirectory = stateDirectory;
        WorkingDirectory = lib.mkForce dataDir;
        KillMode = "control-group";
        TimeoutStopSec = 60;
        # Child runtimes such as PyTorch need executable memory for JIT compilation.
        MemoryDenyWriteExecute = lib.mkForce false;
      };
    };
  };
}

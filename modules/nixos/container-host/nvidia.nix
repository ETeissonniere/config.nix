{ config, lib, ... }:
let
  nvidiaPackage = config.hardware.nvidia.package;
  gpuDevices = [
    "/dev/nvidia0"
    "/dev/nvidiactl"
    "/dev/nvidia-uvm"
    "/dev/nvidia-uvm-tools"
  ];
in
{
  options.containers = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { config, ... }:
        {
          options.nvidia.enable = lib.mkEnableOption "CUDA access to the host's first NVIDIA GPU";

          config = lib.mkIf config.nvidia.enable {
            allowedDevices = map (node: {
              inherit node;
              modifier = "rw";
            }) gpuDevices;
            bindMounts =
              lib.genAttrs gpuDevices (_: {
                isReadOnly = false;
              })
              // {
                # Use the running host's driver libraries to match its kernel module.
                "/run/opengl-driver".isReadOnly = true;
              };
            config = {
              programs.nix-ld.libraries = [ nvidiaPackage ];
              environment.systemPackages = [ nvidiaPackage.bin ];
              environment.sessionVariables.LD_LIBRARY_PATH = [ "/run/opengl-driver/lib" ];
            };
          };
        }
      )
    );
  };
}

{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.comfyui;
  yaml = pkgs.formats.yaml { };
  modelPaths = yaml.generate "comfyui-model-paths.yaml" cfg.extraModelPaths;
  comfyPython = pkgs.python3.override {
    packageOverrides = _final: prev: {
      torch = prev.torch-bin;
      torchvision = prev.torchvision-bin;
    };
  };
in
{
  options.services.comfyui = {
    extraModelPaths = lib.mkOption {
      type = lib.types.attrsOf yaml.type;
      default = { };
      description = "Additional model directories in ComfyUI extra_model_paths.yaml format.";
    };
    command = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      description = "ComfyUI command for external process managers such as llama-swap; does not require enabling the systemd service.";
    };
  };

  config.services.comfyui = {
    package = lib.mkDefault (pkgs.comfyui.override { python3 = comfyPython; });
    extraArgs = lib.mkIf (cfg.extraModelPaths != { }) [
      "--extra-model-paths-config"
      (toString modelPaths)
    ];
    command = lib.escapeShellArgs (
      [
        (lib.getExe cfg.package)
        "--listen"
        (lib.concatStringsSep "," cfg.listen)
        "--port"
        (toString cfg.port)
        "--base-directory"
        cfg.dataDir
      ]
      ++ cfg.extraArgs
    );
  };
}

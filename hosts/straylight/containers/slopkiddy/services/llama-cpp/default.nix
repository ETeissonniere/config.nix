{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.llama-cpp;
in
{
  options.services.llama-cpp.command = lib.mkOption {
    type = lib.types.str;
    readOnly = true;
    description = "llama-server command for external process managers such as llama-swap; does not require enabling the systemd service.";
  };

  config.services.llama-cpp = {
    package = lib.mkDefault (pkgs.llama-cpp.override { cudaSupport = true; });
    command = lib.escapeShellArgs (
      [ (lib.getExe' cfg.package "llama-server") ]
      ++ (lib.cli.toCommandLine (name: {
        option =
          if lib.hasPrefix "-" name then
            name
          else if builtins.stringLength name > 1 then
            "--${name}"
          else
            "-${name}";
        sep = null;
        explicitBool = false;
        formatArg = lib.generators.mkValueStringDefault { };
      }) cfg.settings)
    );
  };
}

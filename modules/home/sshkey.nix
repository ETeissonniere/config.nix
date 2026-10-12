{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sshKey;
  directory = builtins.dirOf cfg.path;
in
{
  options.sshKey = {
    enable = lib.mkEnableOption "a local Ed25519 SSH key";
    path = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/.ssh/id_ed25519";
      description = "Private key generated on activation if it does not already exist.";
    };
  };

  config.home.activation.createSshKey = lib.mkIf cfg.enable (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p ${lib.escapeShellArg directory}
      run chmod 700 ${lib.escapeShellArg directory}
      if [ ! -e ${lib.escapeShellArg cfg.path} ]; then
        run ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -N "" \
          -C ${lib.escapeShellArg config.home.username} -f ${lib.escapeShellArg cfg.path}
      fi
    ''
  );
}

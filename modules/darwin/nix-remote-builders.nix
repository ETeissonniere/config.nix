{
  config,
  lib,
  pkgs,
  ...
}:
let
  builderKey = "/etc/nix/straylight_builder_ed25519";
in
{
  options.nix.remoteBuilders.enable = lib.mkEnableOption "remote Nix builders";

  config = lib.mkIf config.nix.remoteBuilders.enable {
    nix.distributedBuilds = true;
    nix.settings.builders-use-substitutes = true;
    nix.buildMachines = [
      {
        hostName = "straylight.local";
        protocol = "ssh-ng";
        sshUser = "nix-ssh";
        sshKey = builderKey;
        systems = [ "x86_64-linux" ];
        maxJobs = 4;
        speedFactor = 10;
        supportedFeatures = [
          "benchmark"
          "big-parallel"
        ];
      }
    ];

    programs.ssh.knownHosts.straylight = {
      hostNames = [ "straylight.local" ];
      publicKeyFile = ../common/keys/straylight-host.pub;
    };

    programs.ssh.extraConfig = ''
      Host straylight.local
        ConnectTimeout 3
        ConnectionAttempts 1
        ServerAliveInterval 5
        ServerAliveCountMax 2
      Host *
    '';

    system.activationScripts.preActivation.text = ''
      if [ ! -e ${builderKey} ]; then
        ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -N "" \
          -C ${config.networking.hostName}-builder -f ${builderKey}
      fi
      chown root:wheel ${builderKey}
      chmod 600 ${builderKey}
    '';
  };
}

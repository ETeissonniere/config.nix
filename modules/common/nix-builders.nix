{ config, ... }:
{
  home-manager.users.${config.me.username} = {
    imports = [ ../home/sshkey.nix ];
    sshKey = {
      enable = true;
      path = "${config.users.users.${config.me.username}.home}/.ssh/nix_builder_ed25519";
    };
  };

  nix.distributedBuilds = true;
  nix.settings.builders-use-substitutes = true;
  nix.buildMachines = [
    {
      hostName = "straylight.local";
      protocol = "ssh-ng";
      sshUser = "nix-ssh";
      sshKey = config.home-manager.users.${config.me.username}.sshKey.path;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
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
    publicKeyFile = ./keys/straylight-host.pub;
  };

  programs.ssh.extraConfig = ''
    Host straylight.local
      ConnectTimeout 3
      ConnectionAttempts 1
      ServerAliveInterval 5
      ServerAliveCountMax 2
    Host *
  '';
}

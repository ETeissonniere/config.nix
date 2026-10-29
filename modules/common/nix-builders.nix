{
  nix.distributedBuilds = true;
  nix.settings.builders-use-substitutes = true;
  nix.buildMachines = [
    {
      hostName = "straylight.local";
      protocol = "ssh-ng";
      sshUser = "nix-ssh";
      sshKey = "/etc/nix/straylight_builder_ed25519";
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

{
  config,
  inputs,
  hostName,
  lib,
  ...
}:
{
  imports = [
    inputs.self.darwinModules.base
    inputs.self.darwinModules.profiles.workstation
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";
  networking = {
    inherit hostName;
    computerName = lib.strings.toSentenceCase hostName;
    localHostName = hostName;
  };

  users.users.${config.me.username}.uid = 501;

  nix.buildMachines = [
    {
      hostName = "192.168.86.23";
      system = "x86_64-linux";
      protocol = "ssh-ng";
      sshUser = "builder";
      maxJobs = 2;
      supportedFeatures = [ "big-parallel" ];
      publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUFUT2I3cjdJN3FtQXMzdkVtd2twTVg5MWtpRkRMYTVUYS9wc3FwSzFvMXE=";
    }
  ];

  # Compatibility baseline for this installation; do not bump during updates.
  system.stateVersion = 6;
}

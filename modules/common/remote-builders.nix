{ config, lib, ... }:
{
  nix.buildMachines = lib.mkDefault (
    lib.optionals
      (
        builtins.hasAttr config.networking.hostName config.me.builderKeys
        && config.networking.hostName != "lxc-builder"
      )
      [
        {
          hostName = "192.168.86.23";
          system = "x86_64-linux";
          protocol = "ssh-ng";
          sshUser = "builder";
          maxJobs = 2;
          supportedFeatures = [ "big-parallel" ];
          publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUFUT2I3cjdJN3FtQXMzdkVtd2twTVg5MWtpRkRMYTVUYS9wc3FwSzFvMXE=";
        }
      ]
  );

  nix.distributedBuilds = lib.mkDefault (config.nix.buildMachines != [ ]);
  nix.settings.builders-use-substitutes = lib.mkIf config.nix.distributedBuilds true;
}

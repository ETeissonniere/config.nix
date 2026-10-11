{
  config,
  lib,
  pkgs,
  ...
}:
let
  rootHome = if pkgs.stdenv.hostPlatform.isDarwin then "/var/root" else "/root";
  builderKey = "${rootHome}/.ssh/nix-builder";
in
{
  system.sshKeys.nix-builder.path = builderKey;

  nix.buildMachines = lib.mkDefault (
    lib.optionals
      (
        builtins.hasAttr config.networking.hostName config.me.builderKeys
        && config.networking.hostName != "lxc-builder"
      )
      [
        {
          hostName = "lxc-builder.local";
          system = "x86_64-linux";
          protocol = "ssh-ng";
          sshUser = "builder";
          sshKey = builderKey;
          maxJobs = 2;
          supportedFeatures = [ "big-parallel" ];
          publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUFUT2I3cjdJN3FtQXMzdkVtd2twTVg5MWtpRkRMYTVUYS9wc3FwSzFvMXE=";
        }
      ]
  );

  nix.distributedBuilds = lib.mkDefault (config.nix.buildMachines != [ ]);
  nix.settings.builders-use-substitutes = lib.mkIf config.nix.distributedBuilds true;
  programs.ssh.extraConfig = ''
    Host lxc-builder
      HostName lxc-builder.local
  '';
}

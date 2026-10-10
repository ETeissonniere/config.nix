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
  system.activationScripts.${
    if pkgs.stdenv.hostPlatform.isDarwin then "postActivation" else "builderKey"
  }.text =
    ''
      ${pkgs.coreutils}/bin/install -d -m 700 ${rootHome}/.ssh || exit 1
        if [ ! -e ${builderKey} ]; then
          (umask 077; ${pkgs.openssh}/bin/ssh-keygen -q -t ed25519 -N "" -f ${builderKey}) || exit 1
        fi
      ${pkgs.coreutils}/bin/chown 0 ${builderKey} || exit 1
      ${pkgs.coreutils}/bin/chmod 600 ${builderKey} || exit 1
      builder_public_key=$(${pkgs.openssh}/bin/ssh-keygen -y -P "" -f ${builderKey}) || exit 1
      printf '%s\n' "$builder_public_key" > ${builderKey}.pub || exit 1
    '';

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
      HostName 192.168.86.23
  '';
}

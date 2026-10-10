{ config, inputs, ... }:
{
  imports = [ inputs.self.commonModules.me ];
  users.users.deploy = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = builtins.attrValues config.me.sshKeys;
  };
  nix.settings.trusted-users = [ "deploy" ];
  # deploy-rs activates the system profile as root through sudo.
  security.sudo.extraRules = [
    {
      users = [ "deploy" ];
      runAs = "root";
      commands = [
        {
          command = "/nix/store/*-activatable-nixos-system-*/activate-rs";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/current-system/sw/bin/rm ^/tmp/deploy-rs-canary-[a-z0-9]{32}$";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}

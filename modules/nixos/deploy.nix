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
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}

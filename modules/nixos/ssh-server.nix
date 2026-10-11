{ config, inputs, ... }:
{
  imports = [ inputs.self.commonModules.me ];
  services.openssh = {
    enable = true;
    # We only manage keys via Nix.
    authorizedKeysInHomedir = false;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };
  users.users.root.openssh.authorizedKeys.keys = builtins.attrValues config.me.sshKeys;
}

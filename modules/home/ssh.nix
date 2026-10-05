{ config, inputs, ... }:
{
  imports = [ inputs.scauth.homeManagerModules.default ];

  programs.scauth = {
    enable = true;
    identities.default.touchId = true;
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings."*" = {
      ForwardAgent = false;
      IdentityFile = config.programs.scauth.identities.default.identityFile;
      IdentitiesOnly = true;
      SecurityKeyProvider = config.programs.scauth.securityKeyProvider;
    };
  };
}

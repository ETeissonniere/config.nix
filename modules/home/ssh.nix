{ config, ... }:
{
  programs.scauth = {
    enable = true;
    identities.default = { };
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

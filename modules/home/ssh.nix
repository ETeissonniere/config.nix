{
  config,
  ...
}:
{
  programs.scauth = {
    enable = true;
    identities.default.touchId = true;
  };

  home.sessionVariables.SSH_SK_PROVIDER = "/usr/lib/ssh-keychain.dylib";

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings."*" = {
      ForwardAgent = false;
      IdentityFile = config.programs.scauth.identities.default.identityFile;
      IdentitiesOnly = true;
      SecurityKeyProvider = "/usr/lib/ssh-keychain.dylib";
    };
  };
}

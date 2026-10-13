{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [ inputs.scauth.homeManagerModules.default ];

  config = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    programs.scauth = {
      enable = true;
      identities.default = { };
    };

    # Codex uses zsh on macOS; it needs the provider for Git signing too.
    programs.zsh.enable = true;
    # Git invokes ssh-keygen directly, which does not read ~/.ssh/config.
    home.sessionVariables.SSH_SK_PROVIDER = config.programs.scauth.securityKeyProvider;

    programs.ssh.settings."*" = {
      IdentityFile = config.programs.scauth.identities.default.identityFile;
      IdentitiesOnly = true;
      SecurityKeyProvider = config.programs.scauth.securityKeyProvider;
    };
  };
}

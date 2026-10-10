{
  imports = [
    ./apps.nix
    ./dock.nix
    ./system-defaults.nix
    ./wallpaper.nix
  ];

  home-manager.sharedModules = [
    ({ config, ... }: {
      # Codex uses zsh on macOS even though our default shell is fish.
      # Enabling it ensures that the SSH_SK_PROVIDER value is passed
      # to Codex' sandbox so we can keep git signing on.
      programs.zsh.enable = true;

      programs.scauth = {
        enable = true;
        identities.default = { };
      };

      # Git signs through ssh-keygen, which does not read ~/.ssh/config.
      home.sessionVariables.SSH_SK_PROVIDER = config.programs.scauth.securityKeyProvider;
      programs.git.signing = {
        key = config.programs.scauth.identities.default.publicKeyFile;
        format = "ssh";
      };
      programs.ssh.settings."*" = {
        IdentityFile = config.programs.scauth.identities.default.identityFile;
        IdentitiesOnly = true;
        SecurityKeyProvider = config.programs.scauth.securityKeyProvider;
      };
    })
  ];
}

{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../../cli-tools.nix
    ../../codex
    ../../developer-folder.nix
    ../../gh.nix
    ../../git.nix
    ../../neovim.nix
    ../../ssh.nix
    ../../sshkey.nix
    ../../scauth.nix
  ];

  sshKey.enable = lib.mkDefault pkgs.stdenv.hostPlatform.isLinux;
  programs.git.signing.key = lib.mkDefault (
    if pkgs.stdenv.hostPlatform.isDarwin then
      config.programs.scauth.identities.default.publicKeyFile
    else
      config.sshKey.path
  );
}

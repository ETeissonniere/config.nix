{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./codex
    ./developer-folder.nix
    ./gh.nix
    ./git.nix
    ../../sshkey.nix
    ./scauth.nix
  ];

  home.packages = [ pkgs.python3Packages.huggingface-hub ];

  sshKey.enable = lib.mkDefault pkgs.stdenv.hostPlatform.isLinux;
  programs.git.signing.key = lib.mkDefault (
    if pkgs.stdenv.hostPlatform.isDarwin then
      config.programs.scauth.identities.default.publicKeyFile
    else
      config.sshKey.path
  );
}

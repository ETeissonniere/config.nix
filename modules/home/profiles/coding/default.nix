{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./agents.nix
    ./developer-folder.nix
    ./gh.nix
    ./git.nix
    ./scauth.nix
    inputs.self.homeModules.sshkey
    inputs.rex.homeManagerModules.default
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

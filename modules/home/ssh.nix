{
  lib,
  pkgs,
  ...
}:
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings."*" = {
      ForwardAgent = true;
      AddKeysToAgent = "yes";
      IdentityFile = "~/.ssh/id_ed25519";
      UseKeychain = lib.mkIf pkgs.stdenvNoCC.hostPlatform.isDarwin true;
    };
  };
}

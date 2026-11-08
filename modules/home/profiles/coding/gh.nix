{ lib, pkgs, ... }:
{
  programs.gh = {
    enable = true;
    settings = lib.optionalAttrs (!pkgs.stdenv.hostPlatform.isDarwin) { git_protocol = "ssh"; };
    extensions = [ pkgs.gh-stack ];
  };
  # gh auth login writes this file; keep it outside the read-only Nix store.
  xdg.configFile."gh/config.yml".enable = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin false;
}

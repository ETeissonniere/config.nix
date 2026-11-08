{ lib, pkgs, ... }:
{
  programs.gh = {
    enable = true;
    extensions = [ pkgs.gh-stack ];
  };
  # gh auth login writes this file; keep it outside the read-only Nix store.
  xdg.configFile."gh/config.yml".enable = false;
  home.activation.githubSshProtocol = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    run ${lib.getExe pkgs.gh} config set git_protocol ssh
  '';
}

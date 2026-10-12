{ config, pkgs, ... }:
{
  home-manager.sharedModules = [ ../home/fish ];

  programs.fish.enable = true;
  users.users.${config.me.username}.shell = pkgs.fish;
}

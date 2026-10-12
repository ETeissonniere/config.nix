{ config, pkgs, ... }:
{
  programs.fish.enable = true;
  users.users.${config.me.username}.shell = pkgs.fish;
}

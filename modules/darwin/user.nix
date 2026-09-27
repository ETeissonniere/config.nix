{ config, pkgs, ... }:
let
  username = config.me.username;
in
{
  system.primaryUser = username;
  users.knownUsers = [ username ];
  users.users.${username} = {
    home = "/Users/${username}";
    shell = pkgs.fish;
  };

  security.pam.services.sudo_local.touchIdAuth = true;
}

{ config, lib, ... }:
let
  username = config.me.username;
in
{
  system.primaryUser = username;
  users.knownUsers = [ username ];
  users.users.${username} = {
    home = "/Users/${username}";
    uid = lib.mkDefault 501;
  };

  security.pam.services.sudo_local.touchIdAuth = true;
}

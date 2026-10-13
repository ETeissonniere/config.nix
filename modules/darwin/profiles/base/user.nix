{ config, ... }:
let
  username = config.me.username;
in
{
  system.primaryUser = username;
  users.knownUsers = [ username ];
  users.users.${username} = {
    home = "/Users/${username}";
  };

  security.pam.services.sudo_local.touchIdAuth = true;
}

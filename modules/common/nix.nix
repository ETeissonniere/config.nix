{ config, pkgs, ... }:
{
  environment.systemPackages = [ pkgs.nh ];

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ config.me.username ];
  };
  nix.gc = {
    automatic = true;
    options = "--delete-older-than 30d";
  };
}

{
  config,
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    ../me.nix
    ../nix.nix
  ];

  programs.fish.enable = true;
  users.users.${config.me.username}.shell = pkgs.fish;
  home-manager.sharedModules = [ inputs.self.homeModules.profiles.base ];
}

{
  config,
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    inputs.self.lib.commonModules.me
    inputs.self.lib.commonModules.nix
  ];

  programs.fish.enable = true;
  users.users.${config.me.username}.shell = pkgs.fish;
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };
    sharedModules = [ inputs.self.homeModules.profiles.base ];
  };
}

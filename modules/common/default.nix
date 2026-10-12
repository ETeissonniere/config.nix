{
  imports = [
    ./me.nix
    ./nix.nix
    ./fish.nix
  ];

  home-manager.sharedModules = [ ../home/profiles/base ];
}

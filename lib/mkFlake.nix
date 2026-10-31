{ inputs }:
let
  lib = inputs.nixpkgs.lib;

  discoverModules =
    path:
    let
      entries = lib.filterAttrs (
        name: type:
        (type == "regular" && lib.hasSuffix ".nix" name)
        || (type == "directory" && builtins.pathExists (path + "/${name}/default.nix"))
      ) (builtins.readDir path);
    in
    lib.mapAttrs' (name: _: {
      name = lib.removeSuffix ".nix" name;
      value = path + "/${name}";
    }) entries;

in
{
  lib.commonModules = discoverModules ../modules/common // {
    profiles = discoverModules ../modules/common/profiles;
  };
  darwinModules = discoverModules ../modules/darwin // {
    profiles = discoverModules ../modules/darwin/profiles;
  };
  nixosModules = discoverModules ../modules/nixos // {
    profiles = discoverModules ../modules/nixos/profiles;
  };
  homeModules = discoverModules ../modules/home // {
    profiles = discoverModules ../modules/home/profiles;
  };
}
// import ./hosts.nix { inherit inputs; }
// import ./tools.nix { inherit inputs discoverModules; }

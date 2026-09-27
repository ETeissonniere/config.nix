{ inputs }:
let
  lib = inputs.nixpkgs.lib;

  directories = path: lib.filterAttrs (_: type: type == "directory") (builtins.readDir path);

  discoverModules =
    path:
    let
      entries = lib.filterAttrs (
        name: type:
        (type == "regular" && lib.hasSuffix ".nix" name)
        || (type == "directory" && builtins.pathExists (path + "/${name}/default.nix"))
      ) (builtins.readDir path);
      modules = lib.mapAttrs' (name: _: {
        name = lib.removeSuffix ".nix" name;
        value = path + "/${name}";
      }) entries;
    in
    modules;

  withDefaultModule =
    modules:
    modules
    // {
      default.imports = builtins.attrValues (builtins.removeAttrs modules [ "default" ]);
    };
in
{
  commonModules = withDefaultModule (discoverModules ../modules/common);
  darwinModules = withDefaultModule (discoverModules ../modules/darwin);
  homeModules = withDefaultModule (discoverModules ../modules/home);

  darwinConfigurations = lib.mapAttrs (
    hostName: _:
    let
      hostPath = ../hosts + "/${hostName}";
      usersPath = hostPath + "/users";
      users = lib.filterAttrs (
        username: _: builtins.pathExists (usersPath + "/${username}/home-configuration.nix")
      ) (if builtins.pathExists usersPath then directories usersPath else { });
    in
    inputs.nix-darwin.lib.darwinSystem {
      specialArgs = { inherit inputs hostName; };
      modules = [
        (hostPath + "/darwin-configuration.nix")
        inputs.home-manager.darwinModules.home-manager
        {
          nixpkgs.config.allowUnfree = true;
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = { inherit inputs; };
            users = lib.mapAttrs (username: _: usersPath + "/${username}/home-configuration.nix") users;
          };
        }
      ];
    }
  ) (directories ../hosts);

  formatter.aarch64-darwin = inputs.nixpkgs.legacyPackages.aarch64-darwin.nixfmt-tree;
}

{ inputs }:
let
  lib = inputs.nixpkgs.lib;

  directories = path: lib.filterAttrs (_: type: type == "directory") (builtins.readDir path);

  darwinHosts = lib.filterAttrs (
    hostName: _: builtins.pathExists (../hosts + "/${hostName}/darwin-configuration.nix")
  ) (directories ../hosts);

  nixosHosts = lib.filterAttrs (
    hostName: _: builtins.pathExists (../hosts + "/${hostName}/configuration.nix")
  ) (directories ../hosts);

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
  nixosModules = discoverModules ../modules/nixos;
  darwinModules = discoverModules ../modules/darwin // {
    profiles = discoverModules ../modules/darwin/profiles;
  };
  homeModules = discoverModules ../modules/home // {
    profiles = discoverModules ../modules/home/profiles;
  };

  nixosConfigurations = lib.mapAttrs (
    hostName: _:
    lib.nixosSystem {
      specialArgs = { inherit inputs hostName; };
      modules = [ (../hosts + "/${hostName}/configuration.nix") ];
    }
  ) nixosHosts;

  deploy.nodes = lib.mapAttrs (hostName: host: {
    hostname = host.config.networking.hostName;
    sshUser = "deploy";
    profiles.system = {
      user = "root";
      path = inputs.deploy-rs.lib.${host.config.nixpkgs.hostPlatform.system}.activate.nixos host;
    };
  }) inputs.self.nixosConfigurations;

  checks = lib.genAttrs [ "aarch64-darwin" "x86_64-linux" ] (
    system: inputs.deploy-rs.lib.${system}.deployChecks inputs.self.deploy
  );

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
  ) darwinHosts;

  formatter.aarch64-darwin = inputs.nixpkgs.legacyPackages.aarch64-darwin.nixfmt-tree;
  formatter.x86_64-linux = inputs.nixpkgs.legacyPackages.x86_64-linux.nixfmt-tree;
}

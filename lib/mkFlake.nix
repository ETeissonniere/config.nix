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

  discoverUsers =
    hostName:
    let
      usersPath = ../hosts + "/${hostName}/users";
      users = lib.filterAttrs (
        username: _: builtins.pathExists (usersPath + "/${username}/home-configuration.nix")
      ) (if builtins.pathExists usersPath then directories usersPath else { });
    in
    lib.mapAttrs (username: _: usersPath + "/${username}/home-configuration.nix") users;

  homeManagerConfig = hostName: {
    nixpkgs.config.allowUnfree = true;
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = { inherit inputs; };
      users = discoverUsers hostName;
    };
  };

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

in
{
  commonModules = discoverModules ../modules/common;
  darwinModules = discoverModules ../modules/darwin // {
    profiles = discoverModules ../modules/darwin/profiles;
  };
  nixosModules = discoverModules ../modules/nixos // {
    profiles = discoverModules ../modules/nixos/profiles;
  };
  homeModules = discoverModules ../modules/home // {
    profiles = discoverModules ../modules/home/profiles;
  };

  darwinConfigurations = lib.mapAttrs (
    hostName: _:
    inputs.nix-darwin.lib.darwinSystem {
      specialArgs = { inherit inputs hostName; };
      modules = [
        (../hosts + "/${hostName}/darwin-configuration.nix")
        inputs.home-manager.darwinModules.home-manager
        (homeManagerConfig hostName)
      ];
    }
  ) darwinHosts;

  nixosConfigurations = lib.mapAttrs (
    hostName: _:
    inputs.nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs hostName; };
      modules = [
        (../hosts + "/${hostName}/configuration.nix")
        inputs.home-manager.nixosModules.home-manager
        (homeManagerConfig hostName)
      ];
    }
  ) nixosHosts;

  deploy.nodes = lib.mapAttrs (hostName: host: {
    hostname = "${hostName}.local";
    sshUser = host.config.me.username;
    profiles.system = {
      # System activation requires sudo; SSH still uses the primary user's account.
      user = "root";
      path = inputs.deploy-rs.lib.${host.pkgs.stdenv.hostPlatform.system}.activate.nixos host;
    };
  }) inputs.self.nixosConfigurations;

  checks.x86_64-linux = inputs.deploy-rs.lib.x86_64-linux.deployChecks inputs.self.deploy;

  apps = lib.genAttrs [ "aarch64-darwin" "x86_64-linux" ] (system: {
    deploy = inputs.deploy-rs.apps.${system}.default;
    nixos-anywhere = {
      type = "app";
      program = "${inputs.nixos-anywhere.packages.${system}.default}/bin/nixos-anywhere";
    };
  });

  formatter.aarch64-darwin = inputs.nixpkgs.legacyPackages.aarch64-darwin.nixfmt-tree;
  formatter.x86_64-linux = inputs.nixpkgs.legacyPackages.x86_64-linux.nixfmt-tree;
}

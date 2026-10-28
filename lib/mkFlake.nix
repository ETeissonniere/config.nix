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

  darwinConfigurations = lib.mapAttrs (
    hostName: _:
    inputs.nix-darwin.lib.darwinSystem {
      specialArgs = { inherit inputs hostName; };
      modules = [
        inputs.self.lib.commonModules.profiles.base
        inputs.self.darwinModules.profiles.base
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
        inputs.self.lib.commonModules.profiles.base
        (../hosts + "/${hostName}/configuration.nix")
        inputs.home-manager.nixosModules.home-manager
        (homeManagerConfig hostName)
      ];
    }
  ) nixosHosts;

  configurationPaths =
    lib.mapAttrs (_: host: host.system.drvPath) inputs.self.darwinConfigurations
    // lib.mapAttrs (
      _: host: host.config.system.build.toplevel.drvPath
    ) inputs.self.nixosConfigurations;

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

  agenix-rekey = inputs.agenix-rekey.configure {
    userFlake = inputs.self;
    inherit (inputs.self) nixosConfigurations;
    # Use Go age for the post-quantum recipients used throughout this repo.
    agePackage = pkgs: pkgs.age;
  };

  apps = lib.genAttrs [ "aarch64-darwin" "x86_64-linux" ] (system: {
    deploy = {
      type = "app";
      meta.description = "Deploy NixOS configurations with automatic rollback";
      program = "${inputs.nixpkgs.legacyPackages.${system}.deploy-rs}/bin/deploy";
    };
    nixos-anywhere = {
      type = "app";
      meta.description = "Install NixOS on a remote machine";
      program = "${inputs.nixos-anywhere.packages.${system}.default}/bin/nixos-anywhere";
    };
  });

  formatter.aarch64-darwin = inputs.nixpkgs.legacyPackages.aarch64-darwin.nixfmt-tree;
  formatter.x86_64-linux = inputs.nixpkgs.legacyPackages.x86_64-linux.nixfmt-tree;
}

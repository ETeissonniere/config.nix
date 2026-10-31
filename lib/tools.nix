{ inputs, discoverModules }:
let
  lib = inputs.nixpkgs.lib;
  systems = [
    "aarch64-darwin"
    "x86_64-linux"
  ];
  # Secret tools support additional platforms, subject to the pinned Nixpkgs support.
  packageSystems = lib.intersectLists lib.systems.flakeExposed (
    builtins.attrNames inputs.self.agenix-rekey
  );

  tests = lib.genAttrs systems (
    system:
    lib.mapAttrs (_: path: import path { pkgs = inputs.nixpkgs.legacyPackages.${system}; }) (
      discoverModules ../tests
    )
  );

in
{
  checks = lib.mapAttrs (
    system: systemTests: systemTests // inputs.deploy-rs.lib.${system}.deployChecks inputs.self.deploy
  ) tests;

  packages = lib.genAttrs packageSystems (
    system:
    let
      pkgs = inputs.nixpkgs.legacyPackages.${system};
      tools = inputs.self.agenix-rekey.${system};
    in
    {
      agenix-edit-view = tools.edit-view;
      agenix-rekey = tools.rekey;
    }
    // lib.optionalAttrs (builtins.elem system systems) {
      deploy-rs = pkgs.deploy-rs;
      nixos-anywhere = inputs.nixos-anywhere.packages.${system}.default;
      tests = pkgs.linkFarm "tests" tests.${system};
    }
  );

  agenix-rekey = inputs.agenix-rekey.configure {
    userFlake = inputs.self;
    inherit (inputs.self) nixosConfigurations darwinConfigurations;
    # Use Go age for the post-quantum recipients used throughout this repo.
    agePackage = pkgs: pkgs.age;
  };

  formatter = lib.genAttrs systems (system: inputs.nixpkgs.legacyPackages.${system}.nixfmt-tree);
}

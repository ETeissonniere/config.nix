{ inputs, discoverModules }:
let
  lib = inputs.nixpkgs.lib;
  systems = [
    "aarch64-darwin"
    "aarch64-linux"
    "x86_64-linux"
  ];

  macIdentities = lib.unique (
    lib.mapAttrsToList (
      _: host: "${host.config.users.users.${host.config.me.username}.home}/.config/age/identity.key"
    ) inputs.self.darwinConfigurations
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

  packages = lib.genAttrs systems (
    system:
    let
      pkgs = inputs.nixpkgs.legacyPackages.${system};
      tools = inputs.self.agenix-rekey.${system};
    in
    {
      agenix-edit-view = tools.edit-view;
      agenix-rekey = tools.rekey;
      deploy-rs = inputs.deploy-rs.packages.${system}.default;
      nixos-anywhere = inputs.nixos-anywhere.packages.${system}.default;
      tests = pkgs.linkFarm "tests" tests.${system};
    }
    // lib.mapAttrs (_: path: pkgs.callPackage path { }) (discoverModules ../packages)
  );

  agenix-rekey = inputs.agenix-rekey.configure {
    userFlake = inputs.self;
    inherit (inputs.self) nixosConfigurations darwinConfigurations;
    # Use Go age for the post-quantum recipients used throughout this repo.
    agePackage = pkgs: pkgs.age;
    # Rekeying runs on a Mac as its primary user, with that Mac's Secure Enclave identity.
    extraDecryptionArgs = lib.concatMap (identity: [
      "-i"
      identity
    ]) macIdentities;
  };

  formatter = lib.genAttrs systems (system: inputs.nixpkgs.legacyPackages.${system}.nixfmt-tree);
}

{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-things = {
      url = "github:oake/nix-things";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
  };

  outputs =
    inputs:
    let
      blueprint = inputs.nix-things.lib.mkFlake {
        inherit inputs;
        systems = [
          "aarch64-darwin"
          "x86_64-darwin"
        ];
      };
    in
    {
      inherit (blueprint)
        darwinConfigurations
        nixosConfigurations
        commonModules
        darwinModules
        homeModules
        nixosModules
        formatter
        ;
    };
}

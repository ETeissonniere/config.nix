{
  config,
  inputs,
  hostName,
  lib,
  ...
}:
{
  imports = [
    inputs.nix-homebrew.darwinModules.nix-homebrew
  ];

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-darwin";

  nix.settings = {
    trusted-users = lib.mkForce [ "root" ];
    sandbox = true;
  };

  networking = {
    inherit hostName;
    computerName = lib.strings.toSentenceCase hostName;
    localHostName = hostName;
  };

  services.openssh.hostKeys = [ ];

  networking.applicationFirewall = {
    enable = true;
    blockAllIncoming = false;
    allowSigned = true;
    allowSignedApp = true;
  };

  nix-homebrew = {
    enable = true;
    autoMigrate = true;
    user = config.me.username;
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
    };
    mutableTaps = false;
  };

  homebrew = {
    enable = true;
    taps = builtins.attrNames config.nix-homebrew.taps;
    onActivation = {
      cleanup = "zap";
      autoUpdate = true;
      upgrade = true;
    };
  };

  home-manager = {
    backupFileExtension = "before-nix";
  };
}

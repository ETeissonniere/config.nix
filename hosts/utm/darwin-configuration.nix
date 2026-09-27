{ lib, ... }:
{
  imports = [ ../wintermute/darwin-configuration.nix ];

  # Apple Media Services are unavailable in macOS virtual machines.
  homebrew.masApps = lib.mkForce { };
}

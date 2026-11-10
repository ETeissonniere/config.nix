{ inputs, ... }:
{
  imports = [
    ./darwin.nix
    ./user.nix
    inputs.self.darwinModules.mac-default-browser
    inputs.self.darwinModules.mac-shortcuts
    inputs.self.darwinModules.mac-wallpaper
  ];
}

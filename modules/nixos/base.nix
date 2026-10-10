{ inputs, ... }:
{
  imports = [
    inputs.self.commonModules.default
    ./ssh-server.nix
    ./deploy.nix
  ];
}

{ inputs, ... }:
{
  imports = [
    inputs.self.commonModules.default
    ./ssh-server.nix
    ./deploy.nix
  ];
  services.avahi = {
    enable = true;
    nssmdns4 = true;
  };
}

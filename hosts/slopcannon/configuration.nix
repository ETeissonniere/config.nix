{
  config,
  inputs,
  modulesPath,
  ...
}:
{
  imports = [
    inputs.self.nixosModules.profiles.server
    inputs.disko.nixosModules.disko
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disko.nix
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
  boot.loader.grub.enable = true;
  services.qemuGuest.enable = true;

  users.users.${config.me.username} = {
    linger = true;
    extraGroups = [ "docker" ];
  };
  virtualisation.docker.enable = true;

  # Compatibility baseline for this installation; do not bump during updates.
  system.stateVersion = "26.05";
}

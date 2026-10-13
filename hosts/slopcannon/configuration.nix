{
  config,
  inputs,
  modulesPath,
  ...
}:
{
  imports = [
    inputs.self.nixosModules.profiles.server-docker
    inputs.disko.nixosModules.disko
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disko.nix
  ];

  boot.loader.grub.enable = true;
  services.qemuGuest.enable = true;

  users.users.${config.me.username}.linger = true;

  # Compatibility baseline for this installation; do not bump during updates.
  system.stateVersion = "26.05";
}

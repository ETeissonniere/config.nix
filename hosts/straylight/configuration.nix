{ inputs, ... }:
{
  imports = [
    inputs.self.nixosModules.profiles.server

    inputs.self.nixosModules.container-host
    inputs.self.nixosModules.docker
    inputs.self.nixosModules.ephemeral-root
    inputs.self.nixosModules.nix-builder
    inputs.self.nixosModules.nvidia
    inputs.self.nixosModules.secure-boot
    inputs.self.nixosModules.wake-on-lan

    inputs.disko.nixosModules.disko

    ./containers
    ./disko.nix
    ./persistence.nix
  ];

  containerHost.network.mainNetworkInterface = "enp12s0";

  boot.initrd.availableKernelModules = [
    "ahci"
    "nvme"
    "xhci_pci"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];

  # Compatibility baseline for this installation; do not bump during updates.
  system.stateVersion = "26.05";
}

{ inputs, ... }:
{
  imports = [
    inputs.self.nixosModules.container-host
    inputs.self.nixosModules.docker
    inputs.self.nixosModules.nix-builder
    inputs.self.nixosModules.wake-on-lan
    inputs.self.nixosModules.nvidia
    inputs.self.nixosModules.secure-boot
    inputs.self.nixosModules.ephemeral-root
    inputs.disko.nixosModules.disko
    ./disko.nix
    ./containers
    ./persistence.nix
    # Preserve the existing system package order during this reorganization.
    inputs.self.nixosModules.profiles.server
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

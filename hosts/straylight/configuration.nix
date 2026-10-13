{ inputs, ... }:
{
  imports = [
    inputs.self.nixosModules.profiles.server-docker
    inputs.self.nixosModules.profiles.server-wol
    inputs.self.nixosModules.profiles.nvidia
    inputs.self.nixosModules.profiles.secure-boot
    inputs.disko.nixosModules.disko
    ./disko.nix
    ./steam.nix
  ];

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

{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    inputs.self.nixosModules.profiles.server
    inputs.disko.nixosModules.disko
    inputs.lanzaboote.nixosModules.lanzaboote
    ./disko.nix
    ./steam.nix
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
  users.users.${config.me.username}.extraGroups = [ "docker" ];
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.amd.updateMicrocode = true;
  systemd.network.links."10-straylight-lan" = {
    matchConfig = {
      Type = "ether";
      Path = "pci-*";
    };
    linkConfig = {
      NamePolicy = "keep kernel database onboard slot path";
      WakeOnLan = "magic";
    };
  };

  boot = {
    initrd = {
      systemd.enable = true;
      availableKernelModules = [
        "ahci"
        "nvme"
        "xhci_pci"
        "usbhid"
        "usb_storage"
        "sd_mod"
      ];
    };
    loader = {
      systemd-boot.enable = lib.mkForce false;
      efi.canTouchEfiVariables = true;
    };
    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
      configurationLimit = 5;
    };
  };
  security.tpm2.enable = true;
  environment.systemPackages = [ pkgs.sbctl ];

  # Compatibility baseline for this installation; do not bump during updates.
  system.stateVersion = "26.05";
}

{ inputs, lib, ... }:
{
  imports = [
    inputs.self.nixosModules.profiles.server
    inputs.self.nixosModules.container-host
    inputs.self.nixosModules.ephemeral-root
    inputs.nixos-hardware.nixosModules.raspberry-pi-5
    ./containers
    ./sd-image.nix
    ./persistence.nix
  ];

  nixpkgs.hostPlatform = "aarch64-linux";
  hardware.enableAllHardware = lib.mkForce false;
  hardware.raspberry-pi.firmware.uboot.enable = true;
  # Chiba has no TPM; the Pi kernel does not provide the default TPM CRB driver.
  boot.initrd.systemd.tpm2.enable = false;
  containerHost.network.enable = false;
  networking = {
    useDHCP = lib.mkForce false;
    usePredictableInterfaceNames = false;
    interfaces.eth0.ipv4.addresses = [
      {
        address = "192.168.86.51";
        prefixLength = 24;
      }
    ];
    defaultGateway = "192.168.86.1";
    # Keep host resolution independent of the DNS service it runs.
    nameservers = [
      "1.1.1.1"
      "1.0.0.1"
    ];
  };

  # Leave RAM for DNS and avoid parallel builds on the 2 GB board.
  nix.settings = {
    max-jobs = 1;
    cores = 1;
  };
  # Keep tmpfs use low to avoid exhausting the limited available RAM.
  fileSystems."/".options = lib.mkForce [
    "size=256M"
    "mode=755"
  ];
  boot.tmp.tmpfsSize = "128M";
  services.journald.settings.Journal = {
    SystemMaxUse = "64M";
    RuntimeMaxUse = "16M";
  };

  # Compatibility baseline for this installation; do not bump during updates.
  system.stateVersion = "26.05";
}

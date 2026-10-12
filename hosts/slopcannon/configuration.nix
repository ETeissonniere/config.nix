{
  config,
  inputs,
  hostName,
  modulesPath,
  ...
}:
{
  imports = [
    inputs.self.commonModules.default
    inputs.self.nixosModules.profiles.ssh-server
    inputs.disko.nixosModules.disko
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disko.nix
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
  networking = {
    inherit hostName;
    useDHCP = true;
  };
  boot.loader.grub.enable = true;
  services.qemuGuest.enable = true;
  services.avahi = {
    enable = true;
    openFirewall = true;
    publish = {
      enable = true;
      addresses = true;
    };
  };

  users.users.${config.me.username} = {
    isNormalUser = true;
    linger = true;
    extraGroups = [
      "wheel"
      "docker"
    ];
  };
  # Key-only administration lets deploy-rs activate without a password prompt.
  security.sudo.wheelNeedsPassword = false;
  virtualisation.docker.enable = true;
  nix.gc.dates = "weekly";

  # Compatibility baseline for this installation; do not bump during updates.
  system.stateVersion = "26.05";
}

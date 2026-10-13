{
  config,
  inputs,
  hostName,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    inputs.self.nixosModules.profiles.ssh-server
  ];

  environment.systemPackages = [ pkgs.ghostty.terminfo ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.enableRedistributableFirmware = lib.mkDefault true;
  hardware.cpu.amd.updateMicrocode = lib.mkDefault true;

  networking = {
    inherit hostName;
    useDHCP = true;
  };
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
    extraGroups = [ "wheel" ];
  };
  # Key-only administration lets deploy-rs activate without a password prompt.
  security.sudo.wheelNeedsPassword = false;
  nix.gc.dates = "weekly";
}

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
    inputs.self.nixosModules.ssh-server
  ];

  environment.systemPackages = [ pkgs.ghostty.terminfo ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.enableRedistributableFirmware = lib.mkDefault true;
  hardware.cpu.amd.updateMicrocode = lib.mkDefault pkgs.stdenv.hostPlatform.isx86;

  networking = {
    inherit hostName;
    useDHCP = true;
  };
  services.avahi = {
    enable = true;
    openFirewall = true;
    settings.publish = {
      disable-publishing = false;
      publish-addresses = true;
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

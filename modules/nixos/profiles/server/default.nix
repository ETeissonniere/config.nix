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
  zramSwap.enable = true;
  hardware.enableRedistributableFirmware = lib.mkDefault true;

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
  # Avahi exits when the system bus goes away and nothing restarts it, leaving
  # the host unreachable as <host>.local. Starting it with the bus brings it back.
  systemd.services.avahi-daemon.wantedBy = [
    (if config.services.dbus.implementation == "broker" then "dbus-broker.service" else "dbus.service")
  ];
  users.users.${config.me.username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };
  # Key-only administration lets deploy-rs activate without a password prompt.
  security.sudo.wheelNeedsPassword = false;
  # deploy-rs copies locally built closures as this user, who already has
  # passwordless sudo; every other machine trusts only root.
  nix.settings.trusted-users = [ config.me.username ];
  nix.gc.dates = "weekly";
}

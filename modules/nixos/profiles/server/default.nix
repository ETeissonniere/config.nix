{
  config,
  inputs,
  hostName,
  pkgs,
  ...
}:
{
  imports = [
    inputs.self.commonModules.default
    inputs.self.nixosModules.profiles.ssh-server
  ];

  environment.systemPackages = [ pkgs.ghostty.terminfo ];

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

{
  config,
  hostName,
  inputs,
  modulesPath,
  pkgs,
  ...
}:
{
  imports = [
    "${modulesPath}/virtualisation/proxmox-lxc.nix"
    inputs.self.nixosModules.base
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
  networking.hostName = hostName;
  proxmoxLXC.manageHostName = true;

  users.users.builder = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = map (key: "no-touch-required ${key}") (
      builtins.attrValues config.me.builderKeys
    );
  };
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [
        "root"
        "builder"
      ];
    };
    gc = {
      automatic = true;
      options = "--delete-older-than 30d";
    };
  };
  environment.systemPackages = [
    pkgs.git
  ];

  # Compatibility baseline for the first installation.
  system.stateVersion = "26.05";
}

{
  config,
  inputs,
  lib,
  ...
}:
let
  network = config.containerBase.network;
in
{
  options.containerBase.network = {
    enable = lib.mkEnableOption "LAN bridging with DHCP and mDNS for native containers" // {
      default = true;
    };
    mainNetworkInterface = lib.mkOption {
      type = lib.types.str;
      description = "Physical LAN interface to attach to br-lan.";
    };
  };

  options.containers = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        config = {
          specialArgs = { inherit inputs; };
          autoStart = lib.mkDefault true;
          privateUsers = lib.mkDefault "pick";
          privateNetwork = lib.mkDefault true;
          hostBridge = lib.mkIf network.enable (lib.mkDefault "br-lan");
          config = { config, ... }: {
            imports = [
              inputs.self.lib.commonModules.base
              inputs.self.nixosModules.profiles.ssh-server
              inputs.home-manager.nixosModules.home-manager
            ];
            nixpkgs.config.allowUnfree = true;
            users.users.${config.me.username} = {
              isNormalUser = lib.mkDefault true;
              uid = lib.mkDefault 1000;
              homeMode = lib.mkDefault "700";
            };
            # Containers share the host store, so only the host schedules garbage collection.
            nix.gc.automatic = lib.mkForce false;
            home-manager = {
              useGlobalPkgs = lib.mkDefault true;
              useUserPackages = lib.mkDefault true;
              extraSpecialArgs = { inherit inputs; };
            };
            networking = lib.mkIf network.enable {
              useHostResolvConf = false;
              interfaces.eth0.useDHCP = lib.mkDefault true;
            };
            services.avahi = lib.mkIf network.enable {
              enable = lib.mkDefault true;
              openFirewall = lib.mkDefault true;
              publish = {
                enable = lib.mkDefault true;
                addresses = lib.mkDefault true;
              };
            };
          };
        };
      }
    );
  };

  config = lib.mkIf network.enable {
    networking = {
      # Disable global DHCP and enable it only on the LAN bridge below.
      # The host gets its lease on br-lan; native containers request their own leases.
      useDHCP = lib.mkForce false;
      bridges.br-lan.interfaces = [ network.mainNetworkInterface ];
      interfaces.br-lan.useDHCP = true;
    };
    # Keep container interfaces from changing the bridge's DHCP identity.
    systemd.services.br-lan-netdev.postStart = ''
      read -r macAddress < "/sys/class/net/${network.mainNetworkInterface}/address"
      ip link set dev br-lan address "$macAddress"
    '';
    # Docker must not drop forwarding for the native containers' LAN bridge.
    virtualisation.docker.daemon.settings = lib.mkIf config.virtualisation.docker.enable {
      "ip-forward-no-drop" = true;
    };
  };
}

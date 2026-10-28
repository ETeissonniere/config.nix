{ config, ... }:
let
  nasAddress = "192.168.86.29";
  chibaAddress = (builtins.head config.networking.interfaces.eth0.ipv4.addresses).address;
in
{
  networking.firewall = {
    allowedTCPPorts = [ 53 ];
    allowedUDPPorts = [ 53 ];
  };

  containers.coredns = {
    ephemeral = true;
    privateNetwork = false;
    # Binding port 53 on the host network requires capabilities in its user namespace.
    privateUsers = "no";
    config = {
      services.coredns = {
        enable = true;
        config = ''
          teiss.org {
            hosts /dev/null {
              ${nasAddress} grimmory.teiss.org
              ${nasAddress} shelfmark.teiss.org
              ${nasAddress} home.teiss.org
              ${nasAddress} dockhand.teiss.org
              ${nasAddress} nas.teiss.org
              ${nasAddress} immich.teiss.org
              ${nasAddress} gitea.teiss.org
              ${nasAddress} sonarr.teiss.org
              ${nasAddress} radarr.teiss.org
              ${nasAddress} prowlarr.teiss.org
              ${nasAddress} qbit.teiss.org
              ${nasAddress} jellyfin.teiss.org
              ${nasAddress} bazarr.teiss.org
              ${chibaAddress} id.teiss.org
              fallthrough
            }
            log
          }

          . {
            forward . 1.1.1.1 1.0.0.1
            cache 30
            log
          }
        '';
      };
      systemd.services.coredns.serviceConfig = {
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictSUIDSGID = true;
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
      };
      system.stateVersion = "26.05";
    };
  };
  systemd.services."container@coredns".serviceConfig = {
    MemoryMax = "256M";
    TasksMax = 128;
  };
}

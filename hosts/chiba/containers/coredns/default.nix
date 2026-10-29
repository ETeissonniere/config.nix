{ config, lib, ... }:
let
  chibaAddress = (builtins.head config.networking.interfaces.eth0.ipv4.addresses).address;
  slopkiddyAliases = [
    "openwebui"
    "comfy"
  ];
  nasAliases = [
    "grimmory"
    "shelfmark"
    "dockhand"
    "nas"
    "immich"
    "gitea"
    "sonarr"
    "radarr"
    "prowlarr"
    "qbit"
    "jellyfin"
    "bazarr"
  ];
in
{
  # We need to run systemd-resolved here so CoreDNS can resolve .local machine names
  # and resolve the appropriate domains accordingly.
  # This avoids us having to maintain static IPs on our network.
  services.resolved = {
    enable = true;
    settings.Resolve = {
      MulticastDNS = "resolve";
      LLMNR = false;
    };
  };

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
            # Leave 127.0.0.53 available for systemd-resolved's mDNS-capable stub.
            bind ${chibaAddress} 127.0.0.1
            rewrite stop {
              name regex ^(${lib.concatStringsSep "|" slopkiddyAliases})[.]teiss[.]org[.]$ slopkiddy.local.
              answer auto
            }
            rewrite stop {
              name regex ^(${lib.concatStringsSep "|" nasAliases})[.]teiss[.]org[.]$ gollum.local.
              answer auto
            }
            hosts /dev/null {
              ${chibaAddress} auth.teiss.org
              fallthrough
            }
            forward local 127.0.0.53
            log
          }

          . {
            bind ${chibaAddress} 127.0.0.1
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
  systemd.services."container@coredns" = {
    wants = [ "systemd-resolved.service" ];
    after = [ "systemd-resolved.service" ];
    serviceConfig = {
      MemoryMax = "256M";
      TasksMax = 128;
    };
  };
}

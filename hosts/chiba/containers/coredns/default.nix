{ lib, ... }:
let
  staticAddress = "192.168.86.51";
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
  containers.coredns = {
    limits = {
      MemoryMax = "256M";
      TasksMax = 128;
    };
    ephemeral = true;
    config = {
      networking = {
        interfaces.eth0 = {
          useDHCP = false;
          ipv4.addresses = [
            {
              address = staticAddress;
              prefixLength = 24;
            }
          ];
        };
        defaultGateway = "192.168.86.1";
        nameservers = [
          "1.1.1.1"
          "1.0.0.1"
        ];
        firewall = {
          allowedTCPPorts = [ 53 ];
          allowedUDPPorts = [ 53 ];
        };
      };
      services.resolved = {
        enable = true;
        settings.Resolve = {
          MulticastDNS = "resolve";
          LLMNR = false;
        };
      };
      services.coredns = {
        enable = true;
        config = ''
          teiss.org {
            # Leave 127.0.0.53 available for systemd-resolved's mDNS-capable stub.
            bind ${staticAddress} 127.0.0.1
            rewrite stop {
              name regex ^(${lib.concatStringsSep "|" slopkiddyAliases})[.]teiss[.]org[.]$ slopkiddy.local.
              answer auto
            }
            rewrite stop {
              name regex ^(${lib.concatStringsSep "|" nasAliases})[.]teiss[.]org[.]$ gollum.local.
              answer auto
            }
            rewrite stop {
              name exact auth.teiss.org reverse-proxy.local
              answer auto
            }
            forward local 127.0.0.53
            log
          }

          . {
            bind ${staticAddress} 127.0.0.1
            forward . 1.1.1.1 1.0.0.1
            cache 30
            log
          }
        '';
      };
      systemd.services.coredns = {
        wants = [ "systemd-resolved.service" ];
        after = [ "systemd-resolved.service" ];
        serviceConfig = {
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
      };
      system.stateVersion = "26.05";
    };
  };
}

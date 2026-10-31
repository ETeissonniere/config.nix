{ config, ... }:
let
  pocketIdPort = config.containers.pocket-id.config.services.pocket-id.settings.PORT;
in
{
  containers.reverse-proxy = {
    limits = {
      MemoryMax = "256M";
      TasksMax = 128;
    };
    ephemeral = true;
    persistence = {
      directory = "/persist/reverse-proxy";
      directories = [ "/var/lib/caddy" ];
    };
    extraFlags = [
      "--bind-ro=${builtins.dirOf config.age.secrets.caddy-environment.path}:/run/secrets:idmap"
    ];
    config = { pkgs, ... }: {
      networking.firewall.allowedTCPPorts = [
        80
        443
      ];
      services.resolved = {
        enable = true;
        settings.Resolve = {
          MulticastDNS = "resolve";
          LLMNR = false;
        };
      };
      services.caddy = {
        enable = true;
        package = pkgs.caddy.withPlugins {
          plugins = [ "github.com/caddy-dns/cloudflare@v0.2.4" ];
          hash = "sha256-tubXIDCJnO2mvdnPlZclwDhNGaeeYLSt7lnni3+pXDo=";
        };
        environmentFile = "/run/secrets/caddy.env";
        globalConfig = ''
          email {$ACME_EMAIL}
          cert_issuer acme {
            dns cloudflare {env.CF_API_TOKEN}
            # CoreDNS shadows teiss.org; ACME must query public DNS.
            resolvers 1.1.1.1 1.0.0.1
          }
        '';
        virtualHosts."auth.teiss.org".extraConfig = ''
          reverse_proxy pocket-id.local:${toString pocketIdPort}
        '';
      };
      system.stateVersion = "26.05";
    };
  };
  systemd.services."container@reverse-proxy".restartTriggers = [
    config.age.secrets.caddy-environment.file
  ];
}

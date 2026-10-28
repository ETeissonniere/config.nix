{ config, ... }:
{
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  containers.reverse-proxy = {
    ephemeral = true;
    privateNetwork = false;
    privateUsers = "no";
    persistence = {
      directory = "/persist/reverse-proxy";
      directories = [ "/var/lib/caddy" ];
    };
    bindMounts."/run/secrets" = {
      hostPath = builtins.dirOf config.age.secrets.caddy-environment.path;
      isReadOnly = true;
    };
    config = { pkgs, ... }: {
      networking.firewall.enable = false;
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
          reverse_proxy 127.0.0.1:1411
        '';
      };
      system.stateVersion = "26.05";
    };
  };
  systemd.services."container@reverse-proxy".restartTriggers = [
    config.age.secrets.caddy-environment.file
  ];
  systemd.services."container@reverse-proxy".serviceConfig = {
    MemoryMax = "256M";
    TasksMax = 128;
  };
}

{ ... }:
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
      directories = [
        "/var/lib/acme"
        "/var/lib/acme-secrets"
        "/var/lib/caddy"
      ];
    };
    config = {
      networking.firewall.enable = false;
      security.acme = {
        acceptTerms = true;
        defaults = {
          dnsProvider = "cloudflare";
          # CoreDNS shadows teiss.org; ACME must query public DNS.
          dnsResolver = "1.1.1.1:53";
          credentialFiles.CF_DNS_API_TOKEN_FILE = "/var/lib/acme-secrets/cloudflare-token";
        };
        certs."id.teiss.org" = { };
      };
      services.caddy = {
        enable = true;
        virtualHosts."id.teiss.org" = {
          useACMEHost = "id.teiss.org";
          extraConfig = "reverse_proxy 127.0.0.1:1411";
        };
      };
      system.stateVersion = "26.05";
    };
  };
  systemd.services."container@reverse-proxy".serviceConfig = {
    MemoryMax = "256M";
    TasksMax = 128;
  };
}

{ pkgs, ... }:
{
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  services.caddy = {
    enable = true;
    package = pkgs.callPackage ../../../../packages/caddy-cloudflare { };
    globalConfig = ''
      email {$ACME_EMAIL}
      cert_issuer acme {
        dns cloudflare {env.CF_API_TOKEN}
        # Internal DNS shadows teiss.org; ACME must query public DNS.
        resolvers 1.1.1.1 1.0.0.1
      }
    '';
  };
}

{ pkgs, ... }:
{
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
  # Do not export link-local IPv6 addresses into unicast DNS without a scope ID.
  services.avahi.settings.server.use-ipv6 = false;

  services.caddy = {
    enable = true;
    package = pkgs.caddy.withPlugins {
      plugins = [ "github.com/caddy-dns/cloudflare@v0.2.4" ];
      hash = "sha256-tubXIDCJnO2mvdnPlZclwDhNGaeeYLSt7lnni3+pXDo=";
    };
    environmentFile = "/run/secrets/slopkiddy-caddy-environment";
    globalConfig = ''
      email {$ACME_EMAIL}
      cert_issuer acme {
        dns cloudflare {env.CF_API_TOKEN}
        resolvers 1.1.1.1 1.0.0.1
      }
    '';
    virtualHosts."openwebui.teiss.org".extraConfig = ''
      reverse_proxy 127.0.0.1:8080
    '';
    virtualHosts."comfy.teiss.org".extraConfig = ''
      reverse_proxy 127.0.0.1:4180
    '';
  };

  services.oauth2-proxy = {
    enable = true;
    provider = "oidc";
    oidcIssuerUrl = "https://auth.teiss.org";
    keyFile = "/run/secrets/comfyui-oauth-environment";
    httpAddress = "127.0.0.1:4180";
    redirectURL = "https://comfy.teiss.org/oauth2/callback";
    upstream = "http://127.0.0.1:8188/";
    scope = "openid profile email groups";
    email.domains = [ "*" ];
    reverseProxy = true;
    trustedProxyIP = [ "127.0.0.1" ];
    passBasicAuth = false;
    cookie = {
      name = "__Host-comfyui";
      secure = true;
      httpOnly = true;
      refresh = "5m";
      expire = "8h";
    };
    extraConfig = {
      insecure-oidc-allow-unverified-email = true;
      code-challenge-method = "S256";
      skip-provider-button = true;
      proxy-websockets = true;
      upstream-timeout = "3600s";
      cookie-samesite = "lax";
    };
  };
}

{ config, inputs, ... }:
{
  imports = [ inputs.self.nixosModules.profiles.reverse-proxy ];

  services.caddy = {
    environmentFile = "/run/secrets/slopkiddy-caddy-environment";
    virtualHosts."openwebui.teiss.org".extraConfig = ''
      reverse_proxy 127.0.0.1:8080
    '';
    virtualHosts."llama.teiss.org".extraConfig = ''
      @inference {
        # Chiba's Tailscale subnet router presents routed clients with its LAN address.
        remote_ip 192.168.86.0/24 fd13:78d2:adae:4243::/64
        path_regexp ^(/upstream/text)?/v1/(models|chat/completions|completions|responses)$
      }
      handle @inference {
        reverse_proxy 127.0.0.1:${toString config.services.llama-swap.port} {
          header_up -Authorization
          header_up -Cookie
        }
      }
      handle {
        respond 404
      }
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

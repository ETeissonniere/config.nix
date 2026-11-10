{ lib, ... }:
let
  caddyBackendAddress = "10.141.1.1";
  pocketIdBackendAddress = "10.141.1.2";
  backendInterface = address: {
    hostBridge = "br-auth";
    localAddress = "${address}/30";
  };
in
{
  # Services that trust Caddy's forwarded headers listen on a private bridge shared
  # only with the reverse proxy. Direct LAN access would let clients forge those headers.
  networking.bridges.br-auth.interfaces = [ ];
  containers.reverse-proxy.extraVeths.caddy-backend = backendInterface caddyBackendAddress;
  containers.pocket-id = {
    extraVeths.pocket-backend = backendInterface pocketIdBackendAddress;
    config.services.pocket-id.settings.HOST = pocketIdBackendAddress;
  };

  systemd.services = lib.genAttrs [ "container@pocket-id" "container@reverse-proxy" ] (_: {
    requires = [ "br-auth-netdev.service" ];
    after = [ "br-auth-netdev.service" ];
  });
}

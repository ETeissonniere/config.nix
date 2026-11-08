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
    config = { inputs, ... }: {
      imports = [ inputs.self.nixosModules.profiles.reverse-proxy ];
      services.resolved = {
        enable = true;
        settings.Resolve = {
          MulticastDNS = "resolve";
          LLMNR = false;
        };
      };
      services.caddy = {
        environmentFile = "/run/secrets/caddy.env";
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

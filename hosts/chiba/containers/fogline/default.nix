{ config, ... }:
{
  containers.fogline = {
    ephemeral = true;
    limits = {
      MemoryMax = "256M";
      TasksMax = 128;
    };
    persistence = {
      directory = "/persist/fogline";
      directories = [ "/var/lib/fogline" ];
    };
    extraFlags = [
      "--bind-ro=${builtins.dirOf config.age.secrets.fogline-environment.path}:/run/secrets:idmap"
    ];
    config = { inputs, ... }: {
      imports = [ inputs.fogline.nixosModules.default ];
      services.fogline = {
        enable = true;
        openFirewall = true;
        environmentFile = "/run/secrets/calendar.env";
      };
      system.stateVersion = "26.05";
    };
  };
  systemd.services."container@fogline".restartTriggers = [
    config.age.secrets.fogline-environment.file
  ];
}

{
  containers.tailscale = {
    limits = {
      MemoryMax = "256M";
      TasksMax = 128;
    };
    ephemeral = true;
    enableTun = true;
    persistence = {
      directory = "/persist/tailscale";
      directories = [ "/var/lib/tailscale" ];
    };
    config = {
      services.tailscale = {
        enable = true;
        openFirewall = true;
        useRoutingFeatures = "server";
        extraSetFlags = [
          "--advertise-routes=192.168.86.0/24"
          "--accept-dns=true"
        ];
      };
      system.stateVersion = "26.05";
    };
  };
}

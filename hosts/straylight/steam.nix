{
  # The RTX 4080 SUPER stays on the host; CDI exposes it to the gaming container.
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware = {
    nvidia = {
      open = true;
      modesetting.enable = true;
      nvidiaSettings = false;
    };
    nvidia-container-toolkit.enable = true;
  };
  boot.kernelModules = [
    "uinput"
    "fuse"
  ];

  virtualisation.oci-containers = {
    backend = "docker";
    containers.steam = {
      # josh5/steam-headless, linux/amd64, published 2026-10-04.
      image = "docker.io/josh5/steam-headless@sha256:28acbee506844b60fe0a49f1f2a85f4a0a8dbccf8a83db7af73aacbb08d20f74";
      autoStart = false;
      environment = {
        PUID = "1000";
        PGID = "1000";
        UMASK = "077";
        MODE = "primary";
        DISPLAY = ":55";
        WEB_UI_MODE = "vnc";
        PORT_NOVNC_WEB = "8083";
        ENABLE_VNC_AUDIO = "false";
        ENABLE_STEAM = "true";
        STEAM_ARGS = "-silent";
        ENABLE_SUNSHINE = "true";
        SUNSHINE_USER = "admin";
        ENABLE_EVDEV_INPUTS = "true";
        NVIDIA_DRIVER_CAPABILITIES = "all";
      };
      # Root-owned mode 0600, containing USER_PASSWORD and SUNSHINE_PASS.
      environmentFiles = [ "/data/steam/environment" ];
      volumes = [
        "/data/steam/home:/home/default"
        "/data/steam/games:/mnt/games"
      ];
      devices = [
        "nvidia.com/gpu=0"
        "/dev/uinput:/dev/uinput"
        "/dev/fuse:/dev/fuse"
      ];
      extraOptions = [
        # Host networking preserves LAN discovery; desktop ports stay firewalled.
        "--network=host"
        "--shm-size=2g"
        "--ulimit=nofile=1024:524288"
        # Upstream requires these for Xorg, game runtimes and input emulation.
        "--cap-add=SYS_ADMIN"
        "--cap-add=SYS_NICE"
        "--security-opt=seccomp=unconfined"
        "--device-cgroup-rule=c 13:* rwm"
      ];
    };
  };

  systemd.tmpfiles.rules = [
    "d /data/steam 0700 root root -"
    "d /data/steam/home 0700 1000 1000 -"
    "d /data/steam/games 0700 1000 1000 -"
  ];
  systemd.services.docker-steam = {
    unitConfig.RequiresMountsFor = [ "/data/steam" ];
    requires = [ "nvidia-container-toolkit-cdi-generator.service" ];
    after = [ "nvidia-container-toolkit-cdi-generator.service" ];
  };

  # Sunshine streaming only; admin (47990) and desktop (8083) use SSH tunnels.
  networking.firewall = {
    allowedTCPPorts = [
      47984
      47989
      48010
    ];
    allowedUDPPorts = [
      47998
      47999
      48000
    ];
  };
}

{ lib, pkgs, ... }:
let
  prepareContainer = pkgs.writeText "steam-headless-prepare.sh" (
    builtins.readFile ./steam-prepare.sh
  );
  eglLibraries = with pkgs; [
    egl-gbm
    egl-wayland
    egl-wayland2
    egl-x11
  ];
in
{
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "gaming" ''
      if [ "$#" -ne 1 ]; then
        echo "Usage: gaming {on|off|status}" >&2
        exit 2
      fi

      case "$1" in
        on) exec /run/wrappers/bin/sudo ${pkgs.systemd}/bin/systemctl start docker-steam ;;
        off) exec /run/wrappers/bin/sudo ${pkgs.systemd}/bin/systemctl stop docker-steam ;;
        status) exec ${pkgs.systemd}/bin/systemctl status docker-steam --no-pager ;;
        *) echo "Usage: gaming {on|off|status}" >&2; exit 2 ;;
      esac
    '')
  ];

  boot.kernelModules = [
    "uinput"
    "uhid"
    "fuse"
  ];

  virtualisation.oci-containers = {
    containers.steam = {
      # josh5/steam-headless, linux/amd64, published 2026-10-04.
      image = "docker.io/josh5/steam-headless@sha256:28acbee506844b60fe0a49f1f2a85f4a0a8dbccf8a83db7af73aacbb08d20f74";
      autoStart = false;
      environment = {
        TZ = "America/Los_Angeles";
        PUID = "1000";
        PGID = "1000";
        SUNSHINE_NAME = "Straylight";
        NVIDIA_DRIVER_CAPABILITIES = "all";
        # NixOS CDI mounts the GBM backend outside the image's default search path.
        GBM_BACKENDS_PATH = "/usr/local/nvidia/lib64/gbm";
      };
      volumes = [
        "/data/steam/home:/home/steamheadless"
        "/data/steam/games:/mnt/games"
        "/data/steam/state:/var/lib/steam-headless"
        "/data/steam/journal:/var/log/journal"
        # The input subdirectory may not exist until the first virtual device.
        "/sys/devices/virtual:/sys/devices/virtual:ro"
        "${prepareContainer}:/usr/local/sh-init.d/99-host-compatibility.sh:ro"
        # The host already provides mDNS on the shared network namespace.
        "/dev/null:/etc/systemd/system/avahi-daemon.service:ro"
        "/dev/null:/etc/systemd/system/avahi-daemon.socket:ro"
      ]
      # CDI's EGL manifests reference these absolute Nix store paths.
      ++ map (package: "${lib.getLib package}:${lib.getLib package}:ro") eglLibraries;
      devices = [
        "nvidia.com/gpu=0"
        "/dev/uinput:/dev/uinput"
        "/dev/uhid:/dev/uhid"
        "/dev/fuse:/dev/fuse"
      ];
      extraOptions = [
        # Moonlight connects directly over the LAN; administration stays firewalled.
        "--network=host"
        "--hostname=straylight-steam"
        "--tty"
        "--cgroupns=private"
        "--security-opt=writable-cgroups=true"
        "--security-opt=systempaths=unconfined"
        "--tmpfs=/run"
        "--tmpfs=/run/lock"
        "--tmpfs=/tmp"
        "--tmpfs=/dev/input:rw,dev,mode=0755"
        "--stop-signal=SIGRTMIN+3"
        "--stop-timeout=30"
        "--pids-limit=8192"
        "--shm-size=2g"
        "--ulimit=nofile=1024:524288"
        # Upstream requires these for systemd, game runtimes and input emulation.
        "--cap-add=SYS_ADMIN"
        "--cap-add=SYS_NICE"
        "--cap-add=SYS_PTRACE"
        "--cap-add=DAC_READ_SEARCH"
        "--cap-add=NET_ADMIN"
        "--security-opt=seccomp=unconfined"
        "--device-cgroup-rule=c 13:* rwm"
      ];
    };
  };

  systemd.tmpfiles.rules = [
    "d /data/steam 0700 root root -"
    "d /data/steam/home 0700 1000 1000 -"
    "d /data/steam/games 0700 1000 1000 -"
    "d /data/steam/state 0700 root root -"
    "d /data/steam/journal 0700 root root -"
  ];
  systemd.services.docker-steam = {
    unitConfig.RequiresMountsFor = [ "/data/steam" ];
    requires = [ "nvidia-container-toolkit-cdi-generator.service" ];
    after = [ "nvidia-container-toolkit-cdi-generator.service" ];
  };

  # Sunshine streaming only; the administration UI (8483) uses an SSH tunnel.
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

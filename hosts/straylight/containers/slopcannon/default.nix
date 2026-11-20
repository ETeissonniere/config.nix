{
  config,
  inputs,
  ...
}:
let
  inherit (config.me) username sshKeys;
in
{
  containers.slopcannon = {
    limits = {
      MemoryMax = "16G";
      CPUQuota = "800%";
      TasksMax = 4096;
    };
    ephemeral = true;
    nvidia.enable = true;
    allowedDevices = [
      {
        node = "/dev/kvm";
        modifier = "rw";
      }
    ];
    bindMounts."/dev/kvm".isReadOnly = false;
    persistence = {
      directory = "/data/slopcannon";
      directories = [
        "/home"
        "/etc/ssh"
        "/var/lib/nixos"
        "/var/lib/systemd"
        "/var/lib/caddy"
        "/var/log"
        # Useful for builds, discarded on container restarts.
        "/tmp"
        "/var/tmp"
      ];
    };
    # Match the container's private UID mapping, including root-owned secret files.
    extraFlags = [
      "--bind-ro=${builtins.dirOf config.age.secrets.slopcannon-caddy-environment.path}:/run/secrets:idmap"
    ];
    config = {
      imports = [
        inputs.self.lib.commonModules.profiles.base
        inputs.self.nixosModules.ssh-server
        inputs.self.nixosModules.profiles.reverse-proxy
        inputs.home-manager.nixosModules.home-manager
        # Codex CLI sandbox seem to have various issues in the systemd-nspawn container,
        # so we need to enable a couple "hacks" it can work as expected.
        ./codex-fixes.nix
        ./microvm-network-tests.nix
      ];
      me = { inherit username sshKeys; };
      users.users.${username} = {
        isNormalUser = true;
        uid = 1000;
        homeMode = "700";
        # So Codex can run even without an SSH session.
        linger = true;
      };
      # Agents do not need sudo; change the environment through a host Nix rebuild.
      security.sudo.enable = false;
      services.caddy = {
        environmentFile = "/run/secrets/slopcannon-caddy-environment";
        virtualHosts."t3.teiss.org".extraConfig = ''
          # T3's default port; the T3 user service listens only on loopback.
          reverse_proxy 127.0.0.1:3773
        '';
      };
      # Let LAN clients reach development servers without per-project port rules.
      networking.firewall.trustedInterfaces = [ "eth0" ];
      # Prevent inadvertent access to the client laptop's SSH agent from the container.
      services.openssh.settings.AllowAgentForwarding = false;
      # Support Zed's downloaded language servers and other Linux binaries.
      programs.nix-ld.enable = true;
      # Empty the disk-backed scratch directories on each container start. systemd's
      # tmp.conf still removes files older than 10 days (/tmp) and 30 days (/var/tmp).
      systemd.tmpfiles.rules = [
        "D! /tmp 1777 root root"
        "D! /var/tmp 1777 root root"
      ];
      users.mutableUsers = false;
      users.allowNoPasswordLogin = true;

      home-manager.users.${username} = {
        imports = [ inputs.self.homeModules.profiles.coding ];
        services.codex-remote-control.enable = true;
        services.claude-remote-control.enable = true;
        services.t3-remote-control.enable = true;
        home.stateVersion = "26.05";
      };
      system.stateVersion = "26.05";
    };
  };
  systemd.services."container@slopcannon".restartTriggers = [
    config.age.secrets.slopcannon-caddy-environment.file
  ];
}

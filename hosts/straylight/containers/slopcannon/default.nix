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
    ephemeral = true;
    nvidia.enable = true;
    persistence = {
      directory = "/data/slopcannon";
      directories = [
        "/home"
        "/etc/ssh"
        "/var/lib/nixos"
        "/var/lib/systemd"
        "/var/log"
      ];
    };
    config = {
      imports = [
        inputs.self.lib.commonModules.profiles.base
        inputs.self.nixosModules.ssh-server
        inputs.home-manager.nixosModules.home-manager
        # Codex CLI sandbox seem to have various issues in the systemd-nspawn container,
        # so we need to enable a couple "hacks" it can work as expected.
        ./codex-fixes.nix
      ];
      nixpkgs.config.allowUnfree = true;
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
      # Let LAN clients reach development servers without per-project port rules.
      networking.firewall.trustedInterfaces = [ "eth0" ];
      # Prevent inadvertent access to the client laptop's SSH agent from the container.
      services.openssh.settings.AllowAgentForwarding = false;
      # Support Zed's downloaded language servers and other Linux binaries.
      programs.nix-ld.enable = true;
      users.mutableUsers = false;
      users.allowNoPasswordLogin = true;

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        extraSpecialArgs = { inherit inputs; };
        users.${username} = {
          imports = [ inputs.self.homeModules.profiles.coding ];
          services.codex-remote-control.enable = true;
          home.stateVersion = "26.05";
        };
      };
      system.stateVersion = "26.05";
    };
  };

  # These limits can be tuned, but are reasonable defaults for now.
  systemd.services."container@slopcannon".serviceConfig = {
    MemoryMax = "16G";
    CPUQuota = "800%";
    TasksMax = 4096;
  };
}

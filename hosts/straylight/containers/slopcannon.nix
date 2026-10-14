{
  config,
  inputs,
  ...
}:
let
  inherit (config.me) username sshKeys;
in
{
  containers.slopcannon.config = {
    me = { inherit username sshKeys; };
    # Agents do not need sudo; change the environment through a host Nix rebuild.
    security.sudo.enable = false;
    # Prevent inadvertent access to the client laptop's SSH agent from the container.
    services.openssh.settings.AllowAgentForwarding = false;
    # So Codex can run even without an SSH session.
    users.users.${username}.linger = true;
    # Support Zed's downloaded language servers and other Linux binaries.
    programs.nix-ld.enable = true;

    home-manager.users.${username} = {
      imports = [ inputs.self.homeModules.profiles.coding ];
      services.codex-remote-control.enable = true;
      home.stateVersion = "26.05";
    };
    system.stateVersion = "26.05";
  };

  # These limits can be tuned, but are reasonable defaults for now.
  systemd.services."container@slopcannon".serviceConfig = {
    MemoryMax = "16G";
    CPUQuota = "800%";
    TasksMax = 4096;
  };
}

{
  config,
  inputs,
  pkgs,
  ...
}:
let
  scauth = config.home-manager.users.${config.me.username}.programs.scauth;
  agentSocket = "${config.users.users.${config.me.username}.home}/.ssh/scauth/builder-agent.sock";
  builderAgent = pkgs.writeShellScript "builder-ssh-agent" ''
    export SSH_AUTH_SOCK=${agentSocket}
    rm -f "$SSH_AUTH_SOCK"
    /usr/bin/ssh-agent -D -a "$SSH_AUTH_SOCK" &
    agent_pid=$!
    trap 'kill "$agent_pid" 2>/dev/null; wait "$agent_pid"; rm -f "$SSH_AUTH_SOCK"' EXIT
    trap 'exit 0' TERM INT
    for attempt in {1..50}; do
      test -S "$SSH_AUTH_SOCK" && break
      kill -0 "$agent_pid" 2>/dev/null || exit 1
      sleep 0.1
    done
    /usr/bin/ssh-add -S ${scauth.securityKeyProvider} ${scauth.identities.nix-builder.identityFile} || exit 1
    wait "$agent_pid"
  '';
in
{
  # Create a key without Touch ID so Nix can transparently connect to our remote builder.
  home-manager.sharedModules = [ inputs.scauth.homeManagerModules.default ];
  home-manager.users.${config.me.username}.programs.scauth.identities.nix-builder.touchId = false;
  # CTK signing must run in the login session, not in the root Nix daemon.
  launchd.user.agents.nix-builder-agent.serviceConfig = {
    ProgramArguments = [
      "${builderAgent}"
    ];
    KeepAlive = {
      PathState.${scauth.identities.nix-builder.identityFile} = true;
    };
    LimitLoadToSessionType = "Aqua";
  };
  programs.ssh.extraConfig = ''
    Host lxc-builder
      HostName 192.168.86.23
    Match localuser root user builder
      IdentityFile ${scauth.identities.nix-builder.identityFile}
      SecurityKeyProvider ${scauth.securityKeyProvider}
      IdentitiesOnly yes
      IdentityAgent ${agentSocket}
    Match all
  '';
}

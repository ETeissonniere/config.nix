# What network tests of Firecracker microVMs need from the machine: IPv4 forwarding,
# CAP_NET_ADMIN on request, and a web server on a network behind this one.
{
  config,
  pkgs,
  ...
}:
let
  served = pkgs.writeTextDir "hello" "hello from the remote network\n";
in
{
  # Guests reach other networks through this machine.
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  # Guests reach servers on this machine over their tap links, named xsh0, xsh1...
  networking.firewall.trustedInterfaces = [ "xsh+" ];

  # `with-net-admin <command>` runs a command that can create tap links and nftables
  # tables, as can its children. Sessions do not hold the capability themselves:
  # bubblewrap, which the agents' sandboxes use, refuses to start with any capability.
  security.wrappers.with-net-admin = {
    source = "${pkgs.coreutils}/bin/env";
    capabilities = "cap_net_admin+p";
    owner = config.me.username;
    group = "root";
    permissions = "u+rx";
  };

  systemd.services.remote-test-network = {
    description = "Web server on a network behind this machine, for microVM network tests";
    wantedBy = [ "multi-user.target" ];
    path = [
      pkgs.iproute2
      pkgs.python3
      pkgs.util-linux
    ];
    # The server gets a network namespace of its own, joined to this machine by a veth pair.
    serviceConfig.PrivateNetwork = true;
    script = ''
      # PID 1 is in the machine's network namespace.
      ip link add xvh1 type veth peer name xvh0 netns 1
      ip addr add 192.0.2.1/24 dev xvh1
      ip addr add 192.0.2.3/24 dev xvh1
      ip link set xvh1 up
      nsenter --net=/proc/1/ns/net ip addr add 192.0.2.2/24 dev xvh0
      nsenter --net=/proc/1/ns/net ip link set xvh0 up
      exec setpriv --reuid=nobody --regid=nogroup --clear-groups \
        python3 -m http.server 8000 --directory ${served}
    '';
  };
}

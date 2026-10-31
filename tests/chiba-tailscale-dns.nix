{ pkgs }:
pkgs.testers.runNixOSTest {
  name = "chiba-tailscale-dns";

  nodes = {
    server = { config, ... }: {
      # Exercise the host networking settings without starting the Tailscale container.
      imports = [
        { networking = (import ../hosts/chiba/containers/tailscale { inherit config; }).networking; }
      ];
      networking.interfaces.eth0.ipv4.addresses = [
        {
          address = "192.168.86.10";
          prefixLength = 24;
        }
      ];
      networking.firewall.allowedTCPPorts = [ 53 ];
      networking.firewall.allowedUDPPorts = [ 53 ];
      services.coredns = {
        enable = true;
        config = ''
          teiss.org {
            bind 192.168.86.10 127.0.0.1
            hosts {
              192.168.86.10 auth.teiss.org
            }
          }
        '';
      };
    };
    client = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.dig ];
    };
  };

  testScript = ''
    start_all()
    server.wait_for_unit("multi-user.target")
    client.wait_for_unit("multi-user.target")
    server.succeed("ip link set eth1 down; ip link set eth1 name tailscale0; ip link set tailscale0 up")
    server.succeed("ip address add 100.64.0.1/24 dev tailscale0")
    client.succeed("ip address add 100.64.0.2/24 dev eth1")
    # A routed, unreachable destination must not receive the local DNS answer.
    client.succeed("ip route add 203.0.113.1/32 via 100.64.0.1")
    server.succeed("ip route add blackhole 203.0.113.1/32")
    server.wait_for_unit("coredns.service")

    for action in [None, "reload", "restart"]:
        with subtest(f"DNS after firewall {action or 'startup'}"):
            if action:
                server.succeed(f"systemctl {action} firewall.service")
            for transport in ["+notcp", "+tcp"]:
                answer = client.succeed(
                    f"dig @100.64.0.1 auth.teiss.org A {transport} +short +time=2 +tries=1"
                ).strip()
                assert answer == "192.168.86.10", answer
                client.fail(
                    f"dig @203.0.113.1 auth.teiss.org A {transport} +time=1 +tries=1"
                )
  '';
}

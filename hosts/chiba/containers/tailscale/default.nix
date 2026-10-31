{ config, ... }:
let
  chibaAddress = (builtins.head config.networking.interfaces.eth0.ipv4.addresses).address;
in
{
  networking.firewall.allowedUDPPorts = [ 41641 ];
  networking.nat = {
    enable = true;
    # Forward tailnet IPv4 DNS to CoreDNS without intercepting queries routed to other hosts.
    extraCommands = ''
      for protocol in tcp udp; do
        iptables -w -t nat -A nixos-nat-pre -i tailscale0 -m addrtype --dst-type LOCAL \
          -p "$protocol" --dport 53 -j DNAT --to-destination ${chibaAddress}:53
      done
    '';
  };
  # The container shares the host network, so forwarding must be enabled here.
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = true;
    "net.ipv6.conf.all.forwarding" = true;
  };

  containers.tailscale = {
    ephemeral = true;
    privateNetwork = false;
    # Managing the host's tunnel and routes requires capabilities in its user namespace.
    privateUsers = "no";
    enableTun = true;
    persistence = {
      directory = "/persist/tailscale";
      directories = [ "/var/lib/tailscale" ];
    };
    config = {
      # Let the host manage the shared firewall; tailscaled adds its own routing rules.
      networking.firewall.enable = false;
      services.tailscale = {
        enable = true;
        extraSetFlags = [
          "--advertise-routes=192.168.86.0/24"
          "--accept-dns=false"
        ];
      };
      system.stateVersion = "26.05";
    };
  };
  systemd.services."container@tailscale".serviceConfig = {
    MemoryMax = "256M";
    TasksMax = 128;
  };
}

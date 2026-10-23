{
  networking.firewall = {
    allowedTCPPorts = [ 53 ];
    allowedUDPPorts = [ 53 ];
  };

  containers.coredns = {
    ephemeral = true;
    privateNetwork = false;
    # Binding port 53 on the host network requires capabilities in its user namespace.
    privateUsers = "no";
    bindMounts."/etc/coredns" = {
      hostPath = "${./dns}";
      isReadOnly = true;
    };
    config = {
      services.coredns = {
        enable = true;
        config = builtins.readFile ./dns/Corefile;
      };
      systemd.services.coredns.serviceConfig = {
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictSUIDSGID = true;
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
      };
      system.stateVersion = "26.05";
    };
  };
  systemd.services."container@coredns".serviceConfig = {
    MemoryMax = "256M";
    TasksMax = 128;
  };
}

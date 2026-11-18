{ config, ... }:
let
  socketDirectory = "/run/slopkiddy-inference";
  socket = "${socketDirectory}/api.sock";
in
{
  imports = [
    ./slopkiddy
    ./slopcannon
  ];

  # Host SSH and Slopcannon both reach the API without a listener on the LAN.
  systemd.tmpfiles.rules = [ "d ${socketDirectory} 0750 root users -" ];

  containers.slopkiddy = {
    extraFlags = [ "--bind=${socketDirectory}:${socketDirectory}:idmap" ];
    config =
      { pkgs, ... }:
      {
        systemd.sockets.inference-api = {
          wantedBy = [ "sockets.target" ];
          listenStreams = [ socket ];
          socketConfig = {
            SocketGroup = "users";
            SocketMode = "0660";
            RemoveOnStop = true;
          };
        };
        systemd.services.inference-api = {
          after = [ "nginx.service" ];
          requires = [ "nginx.service" ];
          serviceConfig = {
            DynamicUser = true;
            ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd 127.0.0.1:8083";
          };
        };
      };
  };

  containers.slopcannon = {
    extraFlags = [ "--bind-ro=${socketDirectory}:${socketDirectory}:idmap" ];
    config =
      { pkgs, ... }:
      {
        systemd.sockets.inference-api = {
          wantedBy = [ "sockets.target" ];
          listenStreams = [ "127.0.0.1:8082" ];
        };
        systemd.services.inference-api.serviceConfig = {
          User = config.me.username;
          ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd ${socket}";
        };
      };
  };
}

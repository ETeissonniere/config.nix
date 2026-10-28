{ inputs, ... }:
{
  imports = [ inputs.webdash.nixosModules.default ];

  services.webdash.enable = true;
  networking.firewall.allowedTCPPorts = [ 80 ];

  systemd.services.webdash = {
    environment = {
      DASHBOARD_LISTEN = "0.0.0.0:80";
      DASHBOARD_LINKS = builtins.toJSON [
        {
          name = "Open WebUI";
          url = "http://slopkiddy.local:8080";
          group = "AI";
          description = "Chat, image generation, web search, and knowledge";
        }
        {
          name = "ComfyUI";
          url = "http://slopkiddy.local:8188";
          group = "AI";
          description = "Image editing, workflows, models, and LoRAs";
        }
      ];
    };
  };
}

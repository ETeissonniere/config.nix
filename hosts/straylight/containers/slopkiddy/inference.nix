{ config, lib, ... }:
{
  services.llama-cpp.settings = {
    host = "127.0.0.1";
    port = 8081;
    models-dir = "/models/text";
    models-max = 1;
    jinja = true;
    parallel = 2;
    # Let fitting size context per model, offloading to RAM to retain at least 32K per slot.
    fit = "on";
    fit-ctx = 32768;
    fit-target = 2048;
  };
  services.llama-swap = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 8082;
    stateDirectory = "slopkiddy";
    settings = {
      healthCheckTimeout = 600;
      models = {
        text = {
          unlisted = true;
          cmd = config.services.llama-cpp.command;
          proxy = "http://127.0.0.1:8081";
          ttl = 600;
        };
        images = {
          unlisted = true;
          cmd = config.services.comfyui.command;
          proxy = "http://127.0.0.1:8189";
          checkEndpoint = "/system_stats";
          ttl = 0;
          # Open WebUI holds /upstream/images/ws through generation and history lookup.
          compat.ignoreWebsockets = false;
          # UI assets share this limit with API requests and long-lived WebSockets.
          # Match llama-swap's ComfyUI limit to avoid HTTP 429s during page load.
          concurrencyLimit = 999;
        };
      };
      groups.gpu = {
        swap = true;
        exclusive = true;
        members = [
          "text"
          "images"
        ];
      };
    };
  };
  # llama-swap owns the process lifecycle instead of the standalone systemd service.
  services.comfyui = {
    listen = [ "127.0.0.1" ];
    port = 8189;
    dataDir = "/var/lib/slopkiddy/comfyui";
    extraModelPaths.slopkiddy = {
      base_path = "/models/images";
      diffusion_models = "diffusion_models";
      text_encoders = "text_encoders";
      vae = "vae";
      checkpoints = "checkpoints";
      loras = "loras";
    };
    # Share one profile behind OAuth; consider an OIDC-native replacement for personal accounts.
    extraArgs = [
      "--lowvram"
      "--reserve-vram"
      "2"
      "--cache-none"
      "--disable-all-custom-nodes"
      "--disable-partner-nodes"
    ];
  };
  services.nginx = {
    enable = true;
    virtualHosts.comfyui = {
      listen = [
        {
          addr = "127.0.0.1";
          port = 8188;
        }
      ];
      locations."/" = {
        proxyPass = "http://127.0.0.1:8082/upstream/images/";
        proxyWebsockets = true;
        extraConfig = ''
          # ComfyUI compares Host and Origin for browser requests.
          proxy_set_header Host comfy.teiss.org;
          client_max_body_size 100m;
          proxy_read_timeout 3600s;
          proxy_send_timeout 3600s;
        '';
      };
    };
  };
  users.groups.slopkiddy = { };
  users.users.slopkiddy = {
    isSystemUser = true;
    group = "slopkiddy";
    home = "/var/lib/slopkiddy";
  };
  systemd.services.llama-swap.serviceConfig = {
    DynamicUser = lib.mkForce false;
    User = "slopkiddy";
    Group = "slopkiddy";
  };
}

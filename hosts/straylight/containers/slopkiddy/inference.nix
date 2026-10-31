{
  config,
  lib,
  pkgs,
  ...
}:
let
  parallel = 2;
  modelPresets =
    {
      name,
      directory,
      model,
      mmproj ? null,
      slots ? parallel,
      settings ? "",
      contexts ? [
        32
        128
      ],
    }:
    lib.concatMapStringsSep "\n" (context: ''
      [${name}-${toString context}K]
      model = /models/text/${directory}/${model}
      ${lib.optionalString (mmproj != null) "mmproj = /models/text/${directory}/${mmproj}"}
      parallel = ${toString slots}
      ctx-size = ${toString (context * 1024 * slots)}
      ${settings}
    '') contexts;
in
{
  services.llama-cpp.settings = {
    host = "127.0.0.1";
    port = 8081;
    # Explicit presets give models short names; context in each name is per slot.
    models-preset = pkgs.writeText "slopkiddy-models.ini" ''
      version = 1

      ${modelPresets {
        name = "LFM2.5-24B-A2B-QAD";
        directory = "LFM2.5-24B-A2B-QAD-Q4_0";
        model = "LFM2.5-24B-A2B-QAD-Q4_0.gguf";
        slots = 1;
        settings = ''
          temp = 0.1
          top-k = 50
          repeat-penalty = 1.05
          flash-attn = on
        '';
      }}
      ${modelPresets {
        name = "LFM3-Omni-2B";
        directory = "LFM3-Omni-2B-Q8_0";
        model = "LFM3-Omni-2B-Q8_0.gguf";
        mmproj = "mmproj-LFM3-Omni-2B-Q8_0.gguf";
        contexts = [ 32 ];
        settings = ''
          temp = 0
          reasoning = off
        '';
      }}
      ${modelPresets {
        name = "LFM3-VL-2B";
        directory = "LFM3-VL-2B-Q8_0";
        model = "LFM3-VL-2B-Q8_0.gguf";
        mmproj = "mmproj-LFM3-VL-2B-Q8_0.gguf";
        settings = ''
          temp = 0.1
          top-p = 1.0
          top-k = 50
          min-p = 0.0
          repeat-penalty = 1.1
          no-reasoning-preserve = true
        '';
      }}
      ${modelPresets {
        name = "Nemotron-3.5-Bolt-74B";
        directory = "Nemotron-3.5-Bolt-74B-A9B";
        model = "NVIDIA-Nemotron-3.5-Bolt-74B-A9B-24GB.gguf";
        mmproj = "mmproj-NVIDIA-Nemotron-3.5-Bolt-74B-A9B-24GB.gguf";
      }}
      ${modelPresets {
        name = "Qwen3.8-27B-Q4";
        directory = "Qwen3.8-27B-Uncensored-Q4_K_M";
        model = "Qwen3.8-27B-Uncensored-Q4_K_M.gguf";
        mmproj = "mmproj-f16.gguf";
      }}
      ${modelPresets {
        name = "Qwen3.8-27B-Q3";
        directory = "Qwen3.8-27B-Uncensored-Q3_K_M";
        model = "Qwen3.8-27B-Uncensored-Q3_K_M.gguf";
        mmproj = "mmproj-f16.gguf";
      }}
    '';
    models-max = 1;
    jinja = true;
    inherit parallel;
    # Keep preset context sizes fixed while auto-fitting GPU offloading.
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
      globalTTL = 600;
      models = {
        text = {
          unlisted = true;
          cmd = config.services.llama-cpp.command;
          proxy = "http://127.0.0.1:8081";
        };
        images = {
          unlisted = true;
          cmd = config.services.comfyui.command;
          proxy = "http://127.0.0.1:8189";
          checkEndpoint = "/system_stats";
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

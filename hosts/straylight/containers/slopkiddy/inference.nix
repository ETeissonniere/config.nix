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
  # Inkling's relative-position bias disables flash attention, so compute buffers
  # grow with batch size times context; 256K measured too slow to keep.
  inklingPresets =
    {
      slots,
      contexts,
      settings ? "",
    }:
    modelPresets {
      name = "Inkling-2-Mini";
      # Unsloth's Mainline_Support layout, renamed from .gguf_file to .gguf.
      directory = "Inkling-2-Mini-UD-Q4_K_XL";
      model = "Inkling-2-Mini-UD-Q4_K_XL.gguf";
      mmproj = "mmproj-F16.gguf";
      inherit slots contexts;
      settings = ''
        temp = 1.0
        top-p = 1.0
        top-k = 0
        min-p = 0.0
        cache-type-k = q8_0
        cache-type-v = q8_0
        ${settings}
      '';
    };
in
{
  # Inkling 2 Mini needs ggml-org/llama.cpp#32694 (release b12600), and its Unsloth
  # NVFP4 quants need #32704 for correct output. Drop once nixpkgs ships both.
  services.llama-cpp.package =
    assert lib.assertMsg (pkgs.llama-cpp.version == "1.0.0")
      "nixpkgs updated llama-cpp: drop the Inkling 2 Mini override if it has ggml-org/llama.cpp#32694 and #32704.";
    (pkgs.llama-cpp.override { cudaSupport = true; }).overrideAttrs (old: {
      version = "1.0.0-unstable-2026-11-20";
      src = pkgs.fetchFromGitHub {
        owner = "ggml-org";
        repo = "llama.cpp";
        tag = "b12600";
        hash = "sha256-6CcMhIEw2JzuQgAZqk0RnGuIXZ7/g4ofjLbQu9LRQAE=";
      };
      # Vendored from the #32704 branch, which may be rewritten before merging.
      patches = (old.patches or [ ]) ++ [ ./llama-cpp-inkling2-loop-scales.patch ];
      # Master moved the bundled chat UI to ui/, which the nixpkgs recipe cannot build.
      # Open WebUI is the front end here, so skip the UI and its download fallback.
      npmDeps = null;
      nativeBuildInputs = lib.remove pkgs.npmHooks.npmConfigHook old.nativeBuildInputs;
      preConfigure = "";
      cmakeFlags = old.cmakeFlags ++ [
        (lib.cmakeBool "LLAMA_USE_PREBUILT_UI" false)
        # The recipe hardcodes v1.0.0's build info; later definitions win.
        (lib.cmakeFeature "LLAMA_BUILD_NUMBER" "12600")
        (lib.cmakeFeature "LLAMA_BUILD_COMMIT" "29b52d3")
      ];
      # Master includes nvml.h and dlopens the driver's libnvidia-ml at runtime.
      buildInputs = old.buildInputs ++ [ pkgs.cudaPackages.cuda_nvml_dev ];
    });
  services.llama-cpp.settings = {
    host = "127.0.0.1";
    port = 8081;
    # Explicit presets give models short names; context in each name is per slot.
    models-preset = pkgs.writeText "slopkiddy-models.ini" ''
      version = 1

      ${inklingPresets {
        # Two slots measured fastest: 33 t/s alone, 41 t/s across both.
        slots = 2;
        contexts = [ 32 ];
      }}
      ${inklingPresets {
        # Without flash attention, a 128K batch-512 compute buffer outgrows the GPU.
        slots = 1;
        contexts = [ 128 ];
        settings = "ubatch-size = 128";
      }}
      ${modelPresets {
        name = "Nemotron-3.5-Bolt-74B";
        directory = "Nemotron-3.5-Bolt-74B-A9B";
        model = "NVIDIA-Nemotron-3.5-Bolt-74B-A9B-24GB.gguf";
        mmproj = "mmproj-NVIDIA-Nemotron-3.5-Bolt-74B-A9B-24GB.gguf";
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
    # No global parallel: router arguments override each preset's own slot count.
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

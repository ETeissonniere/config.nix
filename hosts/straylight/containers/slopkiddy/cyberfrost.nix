{
  config,
  lib,
  pkgs,
  ...
}:
let
  context = 262144;
  # CPU expert offload can make a full-window prefill take hours.
  requestTimeout = 6 * 3600;
  capabilities = {
    inherit context;
    tools = true;
  };
  ggufModel = "/models/text/CYBER-FROST-3.8-GGUF/CYBER-FROST-3.8-Q2_K.gguf";
  exl3Model = "CYBER-FROST-3.8-EXL3-SAGE-3.35bpw";
  tabby = import ./services/tabbyapi { inherit pkgs; };
  tabbyConfig = (pkgs.formats.yaml { }).generate "config.yml" {
    network = {
      host = "127.0.0.1";
      port = 8899;
      disable_auth = true;
    };
    model = {
      backend = "exllamav3";
      model_dir = "/models/text";
      model_name = exl3Model;
      inline_model_loading = false;
      use_dummy_models = true;
      dummy_model_names = [ "cyberfrost-exl3" ];
      max_seq_len = context;
      cache_size = context;
      cache_mode = "8,8";
      max_batch_size = 1;
      chunk_size = 256;
      # Leave the n-gram table on SSD and reserve most experts for the CPU worker.
      ngram_ram = false;
      cpu_moe_split_experts = 450;
      tool_format = "qwen3_5";
      reasoning = true;
      warmup = true;
    };
    sampling = {
      temperature.override = 1.0;
      top_k.override = 20;
      top_p.override = 0.95;
    };
  };
  tabbyDirectory = pkgs.runCommand "cyberfrost-tabbyapi-config" { } ''
    mkdir -p "$out"
    ln -s ${tabbyConfig} "$out/config.yml"
    ln -s ${tabby.src}/templates ${tabby.src}/sampler_overrides "$out/"
  '';
  serveExl3 = pkgs.writeShellScript "serve-cyberfrost-exl3" ''
    cd ${tabbyDirectory}
    exec ${tabby.python}/bin/python ${tabby.src}/main.py
  '';
in
{
  services.llama-swap.settings = {
    models = {
      cyberfrost-gguf = {
        cmd = lib.escapeShellArgs [
          (lib.getExe' config.services.llama-cpp.package "llama-server")
          "--host"
          "127.0.0.1"
          "--port"
          "8093"
          "--model"
          ggufModel
          "--alias"
          "cyberfrost-gguf"
          "--ctx-size"
          (toString context)
          "--timeout"
          (toString requestTimeout)
          "--parallel"
          "1"
          "--batch-size"
          "256"
          "--ubatch-size"
          "128"
          "--n-gpu-layers"
          "all"
          "--cpu-moe"
          "--load-mode"
          "mmap"
          "--lazy-mode"
          "on"
          "--fit"
          "off"
          "--flash-attn"
          "on"
          "--temp"
          "1.0"
          "--top-k"
          "20"
          "--top-p"
          "0.95"
          "--jinja"
          "--no-webui"
        ];
        proxy = "http://127.0.0.1:8093";
        inherit capabilities;
        concurrencyLimit = 1;
        ttl = 120;
      };
      cyberfrost-exl3 = {
        cmd = toString serveExl3;
        proxy = "http://127.0.0.1:8899";
        checkEndpoint = "/v1/models";
        inherit capabilities;
        concurrencyLimit = 1;
        ttl = 120;
      };
    };
    groups.gpu.members = [
      "cyberfrost-gguf"
      "cyberfrost-exl3"
    ];
  };

  services.nginx.virtualHosts.inference-api = {
    listen = [
      {
        addr = "127.0.0.1";
        port = 8083;
      }
    ];
    # The SSH and container socket only expose inference, not llama-swap's management API.
    locations."~ ^/v1/(models|chat/completions|completions|responses)$" = {
      proxyPass = "http://127.0.0.1:${toString config.services.llama-swap.port}";
      extraConfig = ''
        client_max_body_size 8m;
        proxy_buffering off;
        proxy_read_timeout ${toString requestTimeout}s;
      '';
    };
    locations."/".return = "404";
  };
}

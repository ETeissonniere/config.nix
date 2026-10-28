{ lib, pkgs, ... }:
let
  secretsFile = "/var/lib/slopkiddy-secrets/environment";
  turboWorkflow = builtins.fromJSON (builtins.readFile ./workflows/qwen-image-2.1-turbo.json);
  editWorkflow = lib.recursiveUpdate turboWorkflow {
    "4".inputs = {
      vae = [
        "3"
        0
      ];
      "images.image_1" = [
        "12"
        0
      ];
    };
    "11" = {
      class_type = "LoadImage";
      inputs.image = "input.png";
    };
    "12" = {
      class_type = "JoinImageWithAlpha";
      inputs = {
        image = [
          "11"
          0
        ];
        alpha = [
          "11"
          1
        ];
      };
    };
  };
  workflowNodes = [
    {
      type = "model";
      key = "unet_name";
      node_ids = [ "1" ];
    }
    {
      type = "prompt";
      key = "prompt";
      node_ids = [ "4" ];
    }
    {
      type = "seed";
      key = "noise_seed";
      node_ids = [ "8" ];
    }
  ];

in
{
  users.groups.open-webui = { };
  users.users.open-webui = {
    isSystemUser = true;
    group = "open-webui";
  };
  services.open-webui = {
    enable = true;
    host = "0.0.0.0";
    port = 8080;
    openFirewall = true;
    environmentFile = secretsFile;
    managedSettings = {
      "code_execution.enable" = true;
      "code_execution.engine" = "pyodide";
      "code_interpreter.enable" = true;
      "code_interpreter.engine" = "pyodide";
      # Native date/time tools do not need a code-execution service.
      "models.default_params" = {
        function_calling = "native";
      };
      "models.default_metadata" = {
        capabilities.builtin_tools = true;
        capabilities.code_interpreter = true;
        capabilities.image_generation = true;
        capabilities.web_search = true;
        defaultFeatureIds = [
          "web_search"
          "code_interpreter"
          "image_generation"
        ];
        builtinTools.time = true;
        builtinTools.code_interpreter = true;
        builtinTools.image_generation = true;
        builtinTools.web_search = true;
        builtinTools.files = true;
        builtinTools.knowledge = true;
      };
      "image_generation.enable" = true;
      "image_generation.engine" = "comfyui";
      "image_generation.model" = "qwen-image-2.1-turbo.safetensors";
      "image_generation.size" = "1024x1024";
      "image_generation.steps" = 8;
      "image_generation.prompt.enable" = false;
      "image_generation.comfyui.base_url" = "http://127.0.0.1:8082/upstream/images";
      "image_generation.comfyui.workflow" = builtins.toJSON turboWorkflow;
      "image_generation.comfyui.nodes" = workflowNodes;
      "images.edit.enable" = true;
      "images.edit.engine" = "comfyui";
      "images.edit.model" = "qwen-image-2.1-turbo.safetensors";
      "images.edit.comfyui.base_url" = "http://127.0.0.1:8082/upstream/images";
      "images.edit.comfyui.workflow" = builtins.toJSON editWorkflow;
      "images.edit.comfyui.nodes" = workflowNodes ++ [
        {
          type = "image";
          key = "image";
          node_ids = [ "11" ];
        }
      ];
      "subagents.enable" = true;
      # Match the local backend's two inference slots.
      "subagents.max_concurrent" = 2;
      "subagents.max_async" = 2;
    };

    environment = {
      WEBUI_URL = "http://slopkiddy.local:8080";
      WEBUI_AUTH = "True";
      # The first account can still bootstrap the administrator; further signup is closed.
      ENABLE_SIGNUP = "False";
      ENABLE_OLLAMA_API = "False";
      OPENAI_API_BASE_URL = "http://127.0.0.1:8082/upstream/text/v1";
      OPENAI_API_KEY = "local";
      OPENAI_API_CONFIGS = builtins.toJSON { "0".provider = "llama.cpp"; };
      # Seed defaults on first startup; retain subsequent choices made in the UI.
      ENABLE_PERSISTENT_CONFIG = "True";
      AIOHTTP_CLIENT_TIMEOUT = "3600";

      ENABLE_WEB_SEARCH = "True";
      WEB_SEARCH_ENGINE = "searxng";
      SEARXNG_QUERY_URL = "http://127.0.0.1:8888/search?q=<query>&format=json";
      WEB_SEARCH_RESULT_COUNT = "5";
      WEB_SEARCH_CONCURRENT_REQUESTS = "2";
      DEFAULT_INTERFACE_SETTINGS = builtins.toJSON { webSearch = "always"; };
      # Download this small embedding model into persistent state on first startup.
      RAG_EMBEDDING_ENGINE = "";
      RAG_EMBEDDING_MODEL = "sentence-transformers/all-MiniLM-L6-v2";
      RAG_EMBEDDING_MODEL_TRUST_REMOTE_CODE = "False";
      USE_CUDA_DOCKER = "False";
      ENABLE_KNOWLEDGE_FILE_RETENTION = "True";
      USER_PERMISSIONS_WORKSPACE_KNOWLEDGE_ACCESS = "True";
      CHUNK_SIZE = "1000";
      CHUNK_OVERLAP = "100";
      RAG_TOP_K = "5";

      ENABLE_FOLLOW_UP_GENERATION = "False";
      ENABLE_MEMORY_BACKGROUND_REVIEW = "False";
      SCARF_NO_ANALYTICS = "True";
      DO_NOT_TRACK = "True";
      ANONYMIZED_TELEMETRY = "False";
    };
  };

  services.searx = {
    enable = true;
    environmentFile = secretsFile;
    settings = {
      server = {
        bind_address = "127.0.0.1";
        port = 8888;
        secret_key = "$SEARX_SECRET_KEY";
        limiter = false;
      };
      search.formats = [ "json" ];
    };
  };

  systemd.services.slopkiddy-secrets = {
    description = "Create persistent local application secrets";
    requiredBy = [
      "open-webui.service"
      "searx-init.service"
    ];
    before = [
      "open-webui.service"
      "searx-init.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      UMask = "0077";
      StateDirectory = "slopkiddy-secrets";
      StateDirectoryMode = "0700";
    };
    script = ''
      if [ ! -s ${secretsFile} ]; then
        temporary=$(mktemp /var/lib/slopkiddy-secrets/environment.XXXXXX)
        trap 'rm -f "$temporary"' EXIT
        printf 'WEBUI_SECRET_KEY=%s\nSEARX_SECRET_KEY=%s\n' \
          "$(${lib.getExe pkgs.openssl} rand -hex 32)" \
          "$(${lib.getExe pkgs.openssl} rand -hex 32)" > "$temporary"
        mv "$temporary" ${secretsFile}
      fi
    '';
  };
  systemd.services.open-webui = {
    # DynamicUser would relocate StateDirectory beneath /var/lib/private,
    # which cannot move this container's persistent bind mount.
    serviceConfig = {
      DynamicUser = lib.mkForce false;
      User = "open-webui";
      Group = "open-webui";
    };
    wants = [
      "llama-swap.service"
      "searx.service"
    ];
    after = [
      "llama-swap.service"
      "searx.service"
    ];
  };
}

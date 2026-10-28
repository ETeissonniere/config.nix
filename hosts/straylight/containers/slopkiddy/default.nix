{ config, ... }:
let
  storage = config.containers.slopkiddy.persistence.directory;
in
{
  containers.slopkiddy = {
    ephemeral = true;
    nvidia.enable = true;
    persistence = {
      directory = "/data/slopkiddy";
      directories = [
        "/var/lib/slopkiddy"
        "/var/lib/slopkiddy-secrets"
        "/var/lib/open-webui"
      ];
    };
    # Manually populated SSD storage; model weights never enter the Nix store.
    bindMounts."/models" = {
      hostPath = "${storage}/models";
      isReadOnly = true;
    };
    config = {
      imports = [
        ./services/open-webui
        ./services/comfyui
        ./services/llama-cpp
        ./services/llama-swap
        ./dashboard.nix
        ./inference.nix
        ./webui.nix
      ];
      nixpkgs.config.allowUnfree = true;
      networking.hostName = "slopkiddy";
      programs.nix-ld.enable = true;
      system.stateVersion = "26.05";
    };
  };

  systemd.tmpfiles.rules = [
    # Reach models without granting directory listing access to container state.
    "a+ ${storage} - - - - u:${config.me.username}:--x"
    "A+ ${storage}/models - - - - u:${config.me.username}:rwX,d:u:${config.me.username}:rwx"
    "d ${storage}/models 0755 root root -"
    "d ${storage}/models/text 0755 root root -"
    "d ${storage}/models/images 0755 root root -"
    "d ${storage}/models/images/diffusion_models 0755 root root -"
    "d ${storage}/models/images/text_encoders 0755 root root -"
    "d ${storage}/models/images/vae 0755 root root -"
    "d ${storage}/models/images/checkpoints 0755 root root -"
    "d ${storage}/models/images/loras 0755 root root -"
  ];
}

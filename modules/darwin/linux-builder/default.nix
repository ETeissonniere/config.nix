{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.linux-builder;
  connect = pkgs.writeShellApplication {
    name = "linux-builder-connect";
    runtimeInputs = [ pkgs.socat ];
    runtimeEnv.STARTUP_TIMEOUT = toString cfg.startupTimeout;
    text = builtins.readFile ./connect.sh;
  };
in
{
  options.services.linux-builder = {
    enable = lib.mkEnableOption "on-demand Linux builds with automatic idle shutdown";
    config = lib.mkOption {
      type = lib.types.deferredModule;
      default = { };
      description = "Host-specific NixOS configuration for the Linux builder.";
    };
    startupTimeout = lib.mkOption {
      type = lib.types.ints.positive;
      default = 120;
      description = "Seconds to wait for the builder's SSH service to become ready.";
    };
    idleTimeout = lib.mkOption {
      type = lib.types.ints.positive;
      default = 180;
      description = "Idle seconds before shutdown, checked once per minute. SSH connections and build processes keep the VM awake.";
    };
  };

  config = lib.mkIf cfg.enable {
    nix.linux-builder = {
      enable = true;
      ephemeral = true;
      config =
        { config, options, ... }:
        let
          upstream =
            name:
            (import "${inputs.nixpkgs-linux-builder}/nixos/modules/profiles/${name}.nix" {
              inherit config lib options;
            }).config;
        in
        {
          imports = [
            cfg.config
            (import ./guest.nix { inherit (cfg) idleTimeout; })
          ];
          # Keep the installed Linux guest usable while applying the host-side fixes.
          # Drop these overrides when the fleet pin includes https://discourse.nixos.org/t/81001
          # https://nixpk.gs/pr-tracker.html?pr=582262
          system.build.macos-builder-installer = lib.mkForce (upstream "nix-builder")
            .system.build.macos-builder-installer;
          # https://nixpk.gs/pr-tracker.html?pr=582263
          virtualisation.forwardPorts = lib.mkForce (upstream "nix-builder-vm").virtualisation.forwardPorts;
        };
    };
    environment.etc."ssh/ssh_config.d/100-linux-builder.conf".text = lib.mkAfter ''
      ProxyCommand ${lib.getExe connect}
    '';
    launchd.daemons.linux-builder.serviceConfig = {
      RunAtLoad = lib.mkForce false;
      KeepAlive = lib.mkForce false;
    };
  };
}

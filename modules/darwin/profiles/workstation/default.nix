{
  config,
  inputs,
  lib,
  ...
}:
let
  cfg = config.workstation;
in
{
  imports = [
    ./apps.nix
    ./dock.nix
    ./system-defaults.nix
    ./wallpaper.nix
    inputs.self.darwinModules.nas
    inputs.self.darwinModules.time-machine
    inputs.self.darwinModules.linux-builder
    inputs.self.darwinModules.nix-remote-builders
  ];

  options.workstation = {
    nas.enable = lib.mkEnableOption "NAS credentials and personal share mounts";
    timeMachineOnNAS.enable = lib.mkEnableOption "Time Machine backups on the NAS";
    linuxBuilder.enable = lib.mkEnableOption "a local ARM Linux builder";
    linuxBuilder.cores = lib.mkOption {
      type = lib.types.ints.positive;
      default = 6;
      description = "CPU cores assigned to the local Linux builder.";
    };
    linuxBuilder.memoryGiB = lib.mkOption {
      type = lib.types.ints.positive;
      default = 6;
      description = "Memory assigned to the local Linux builder in GiB.";
    };
    linuxBuilder.diskGiB = lib.mkOption {
      type = lib.types.ints.positive;
      default = 64;
      description = "Disk capacity of the local Linux builder in GiB.";
    };
    nixRemoteBuilders.enable = lib.mkEnableOption "remote Nix builders";
  };

  config = {
    nix.remoteBuilders.enable = cfg.nixRemoteBuilders.enable;

    assertions = [
      {
        assertion = cfg.timeMachineOnNAS.enable -> cfg.nas.enable;
        message = "workstation.timeMachineOnNAS.enable requires workstation.nas.enable.";
      }
    ];
    services.linux-builder = {
      enable = cfg.linuxBuilder.enable;
      config.virtualisation = {
        cores = cfg.linuxBuilder.cores;
        memorySize = lib.mkForce (cfg.linuxBuilder.memoryGiB * 1024);
        darwin-builder.diskSize = cfg.linuxBuilder.diskGiB * 1024;
        fileSystems."/".autoResize = true;
      };
    };
    # Drop this override once the fleet pin includes both fixes in https://discourse.nixos.org/t/81001
    # https://nixpk.gs/pr-tracker.html?pr=582262 (keeping the private key out of the store)
    # https://nixpk.gs/pr-tracker.html?pr=582263 (binding the SSH port to loopback)
    nix.linux-builder.package =
      inputs.nixpkgs-linux-builder.legacyPackages.${config.nixpkgs.hostPlatform.system}.darwin.linux-builder;

    services.nas = {
      enable = cfg.nas.enable;
      smbServerHost = "nas.teiss.org";
      smbAccount = "Eliott";
      smbShares = [ "personal_folder" ];
      agePasswordFile = lib.mkIf cfg.nas.enable config.age.secrets.personal-nas-password.file;
    };
    services.time-machine = {
      enable = cfg.timeMachineOnNAS.enable && config.services.nas.enable;
      inherit (config.services.nas)
        smbServerHost
        smbAccount
        agePasswordFile
        ageIdentityFile
        ;
      smbShare = "Eliott's Time Machine";
      exclusions = map (path: "${config.users.users.${config.me.username}.home}/${path}") [
        "Developer"
        "Downloads"
      ];
    };

    # Compatibility baseline for these installations; do not bump during updates.
    system.stateVersion = 6;
  };
}

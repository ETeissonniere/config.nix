{
  config,
  inputs,
  hostName,
  lib,
  pkgs,
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
    ./secrets.nix
    inputs.self.darwinModules.nas
    inputs.self.darwinModules.time-machine
    inputs.self.darwinModules.linux-builder
  ];

  options.workstation = {
    nas.enable = lib.mkEnableOption "NAS credentials and personal share mounts";
    timeMachine.enable = lib.mkEnableOption "encrypted Time Machine backups to the NAS";
    timeMachine.generatePassword = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Generate a missing backup encryption password. Leave disabled for an existing backup and import its password instead.";
    };
    linuxBuilder.enable = lib.mkEnableOption "the local ARM Linux builder for Raspberry Pi hosts";
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
    nixRemoteBuilders.enable = lib.mkEnableOption "the straylight x86 Linux builder";
  };

  config = lib.mkMerge [
    {
      nixpkgs.hostPlatform = lib.mkDefault "aarch64-darwin";
      nix.settings.trusted-users = lib.mkForce [ "root" ];
      nix.settings.sandbox = true;

      networking = {
        inherit hostName;
        computerName = lib.strings.toSentenceCase hostName;
        localHostName = hostName;
      };
      users.users.${config.me.username}.uid = lib.mkDefault 501;

      assertions = [
        {
          assertion = cfg.timeMachine.enable -> cfg.nas.enable;
          message = "workstation.timeMachine.enable requires workstation.nas.enable.";
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

      services.nas = {
        enable = cfg.nas.enable;
        smbServerHost = "nas.teiss.org";
        smbAccount = "Eliott";
        smbShares = [ "personal_folder" ];
        agePasswordFile = lib.mkIf cfg.nas.enable config.age.secrets.nas-password.rekeyFile;
      };
      services.time-machine = {
        enable = cfg.timeMachine.enable && config.services.nas.enable;
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
    }
    (lib.mkIf cfg.nixRemoteBuilders.enable (import inputs.self.lib.commonModules.nix-builders))
    (lib.mkIf cfg.nixRemoteBuilders.enable {
      system.activationScripts.preActivation.text = ''
        if [ ! -e /etc/nix/straylight_builder_ed25519 ]; then
          ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -N "" \
            -C ${hostName}-builder -f /etc/nix/straylight_builder_ed25519
        fi
        chown root:wheel /etc/nix/straylight_builder_ed25519
        chmod 600 /etc/nix/straylight_builder_ed25519
      '';
    })
  ];
}

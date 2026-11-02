{ inputs, pkgs }:
let
  lib = inputs.nixpkgs.lib;
  host = inputs.self.darwinConfigurations.wintermute;
  withFlags =
    flags:
    host.extendModules {
      modules = [ { workstation = lib.mapAttrs (_: enable: { enable = lib.mkForce enable; }) flags; } ];
    };
  disabled = withFlags {
    nas = false;
    timeMachine = false;
    linuxBuilder = false;
    nixRemoteBuilders = false;
  };
  nasOnly = withFlags {
    nas = true;
    timeMachine = false;
    linuxBuilder = false;
    nixRemoteBuilders = false;
  };
  localOnly = withFlags {
    nas = false;
    timeMachine = false;
    linuxBuilder = true;
    nixRemoteBuilders = false;
  };
  remoteOnly = withFlags {
    nas = false;
    timeMachine = false;
    linuxBuilder = false;
    nixRemoteBuilders = true;
  };
  invalid = withFlags {
    nas = false;
    timeMachine = true;
    linuxBuilder = false;
    nixRemoteBuilders = false;
  };
  resized = host.extendModules {
    modules = [
      {
        workstation.linuxBuilder = {
          cores = 8;
          memoryGiB = 12;
          diskGiB = 96;
        };
      }
    ];
  };
  generated = host.extendModules {
    modules = [ { workstation.timeMachine.generatePassword = true; } ];
  };
  vm = resized.config.nix.linux-builder.package.nixosConfig.virtualisation;
  defaults = host.config.nix.linux-builder.package.nixosConfig.virtualisation;
  backupPassword = inputs.self.outPath + "/secrets/wintermute/time-machine-password.age";
in
assert
  defaults.cores == 6
  && defaults.memorySize == 6 * 1024
  && defaults.darwin-builder.diskSize == 64 * 1024;
assert vm.cores == 8 && vm.memorySize == 12 * 1024 && vm.darwin-builder.diskSize == 96 * 1024;
assert !host.config.workstation.timeMachine.generatePassword;
assert (host.config.age.secrets ? time-machine-password) == builtins.pathExists backupPassword;
assert
  !(host.config.age.secrets ? time-machine-password)
  || host.config.age.secrets.time-machine-password.generator == null;
assert generated.config.age.secrets.time-machine-password.generator != null;
assert !disabled.config.services.nas.enable;
assert !disabled.config.services.time-machine.enable;
assert !disabled.config.services.linux-builder.enable;
assert disabled.config.nix.buildMachines == [ ];
assert !(disabled.config.age.secrets ? personal-nas-password);
assert !(disabled.config.age.secrets ? time-machine-password);
assert !(disabled.config.programs.ssh.knownHosts ? straylight);
assert nasOnly.config.services.nas.enable && !nasOnly.config.services.time-machine.enable;
assert
  toString nasOnly.config.age.secrets.personal-nas-password.rekeyFile
  == inputs.self.outPath + "/secrets/shared/personal-nas-password.age";
assert
  localOnly.config.services.linux-builder.enable
  && !(localOnly.config.programs.ssh.knownHosts ? straylight);
assert
  !remoteOnly.config.services.linux-builder.enable
  && builtins.length remoteOnly.config.nix.buildMachines == 1;
assert lib.any (assertion: !assertion.assertion) invalid.config.assertions;
# Force complete configurations so missing options and service assertions are checked.
assert builtins.all (configuration: builtins.isString configuration.system.drvPath) [
  disabled
  nasOnly
  localOnly
  remoteOnly
  resized
  generated
];
pkgs.runCommand "workstation-options" { } "touch $out"

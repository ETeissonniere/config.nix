{
  config,
  inputs,
  lib,
  ...
}:
{
  imports = [ inputs.self.darwinModules.secrets ];

  age.secrets.personal-nas-password = lib.mkIf config.services.nas.enable {
    rekeyFile = ../../secrets/shared/personal-nas-password.age;
    intermediary = true;
  };
}

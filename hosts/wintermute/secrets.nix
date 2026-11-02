{
  config,
  lib,
  ...
}:
{
  age = {
    # NAS setup decrypts this intermediary secret as the user. The agenix
    # installer would only install a dummy file, so leave it disabled here.
    enable = false;
    secrets.personal-nas-password = lib.mkIf config.services.nas.enable {
      rekeyFile = ../../secrets/shared/personal-nas-password.age;
      intermediary = true;
    };
  };
}

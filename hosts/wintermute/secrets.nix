{ config, lib, ... }:
{
  age = {
    # NAS setup decrypts the host ciphertext as the user with its Secure Enclave key.
    enable = false;
    secrets.personal-nas-password = lib.mkIf config.services.nas.enable {
      rekeyFile = ../../secrets/shared/personal-nas-password.age;
    };
  };
}

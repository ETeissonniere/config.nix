{
  config,
  inputs,
  hostName,
  lib,
  ...
}:
let
  recipientPath = name: ../../../../secrets/recipients + "/${name}.pub";
  readRecipient = name: lib.trim (builtins.readFile (recipientPath name));
  backup = config.workstation.timeMachine;
  backupPassword = ../../../../secrets + "/${hostName}/time-machine-password.age";
in
{
  imports = [
    inputs.agenix.darwinModules.default
    inputs.agenix-rekey.darwinModules.default
  ];
  age = {
    # The NAS module decrypts the password when needed, using the user's Secure
    # Enclave key. Keep the secret registered here, but skip agenix's installer:
    # for an intermediary secret, it would only install a dummy file.
    enable = false;
    secrets.nas-password = lib.mkIf config.services.nas.enable {
      rekeyFile = ../../../../secrets/shared/nas-password.age;
      intermediary = true;
    };
    secrets.time-machine-password =
      lib.mkIf (backup.enable && (backup.generatePassword || builtins.pathExists backupPassword))
        {
          # Retained for recovery; macOS manages backup encryption.
          rekeyFile = backupPassword;
          intermediary = true;
          generator = lib.mkIf backup.generatePassword { script = "alnum"; };
        };
    rekey = {
      storageMode = "local";
      localStorageDir = inputs.self.outPath + "/secrets/rekeyed/${hostName}";
      hostPubkey = readRecipient hostName;
      masterIdentities = [
        {
          identity = "\"\${AGENIX_IDENTITY:-$HOME/.config/age/identity.key}\"";
          pubkey = readRecipient "wintermute";
        }
      ];
      extraEncryptionPubkeys = [ (readRecipient "recovery") ];
    };
  };
}

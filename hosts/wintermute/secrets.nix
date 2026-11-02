{ inputs, lib, ... }:
let
  readRecipient =
    name: lib.removeSuffix "\n" (builtins.readFile (../../secrets/recipients + "/${name}.pub"));
in
{
  imports = [
    inputs.agenix.darwinModules.default
    inputs.agenix-rekey.darwinModules.default
  ];
  age = {
    # Intermediary secrets substitute dummy files; skip their agenix installation.
    # The NAS module decrypts its rekeyFile as the primary user for Keychain setup.
    enable = false;
    secrets.nas-password = {
      rekeyFile = ../../secrets/wintermute/nas-password.age;
      intermediary = true;
    };
    secrets.time-machine-password = {
      # Retained for recovery; macOS manages the existing backup's encryption.
      rekeyFile = ../../secrets/wintermute/time-machine-password.age;
      intermediary = true;
    };
    rekey = {
      storageMode = "local";
      localStorageDir = inputs.self.outPath + "/secrets/rekeyed/wintermute";
      hostPubkey = readRecipient "wintermute";
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

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
    # The NAS module decrypts the password when needed, using the user's Secure
    # Enclave key. Keep the secret registered here, but skip agenix's installer:
    # for an intermediary secret, it would only install a dummy file.
    enable = false;
    secrets.nas-password = {
      rekeyFile = ../../secrets/wintermute/nas-password.age;
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

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
    # Keychain owns the runtime credential. Decrypt as the logged-in user during
    # NAS setup, rather than asking a root boot daemon to use the Secure Enclave.
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

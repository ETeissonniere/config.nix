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
    # agenix-rekey substitutes dummy files for intermediary secrets. The NAS
    # module decrypts the real file as the primary user with their Secure Enclave
    # identity, so disable agenix's dummy installation.
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

{
  inputs,
  hostName,
  lib,
  ...
}:
let
  recipientPath = name: ../../secrets/recipients + "/${name}.pub";
  readRecipient = name: lib.trim (builtins.readFile (recipientPath name));
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
    rekey = {
      storageMode = "local";
      localStorageDir = inputs.self.outPath + "/secrets/rekeyed/${hostName}";
      hostPubkey = readRecipient hostName;
      # Shared source secrets are encrypted for Wintermute. hostPubkey above
      # selects the Mac that receives rekeyed secrets; it is not the master key.
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

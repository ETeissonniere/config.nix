{ inputs, ... }:
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
      hostPubkey = builtins.readFile ../../secrets/recipients/wintermute.pub;
      masterIdentities = [
        {
          identity = "\"\${AGENIX_IDENTITY:-$HOME/.config/age/identity.key}\"";
          pubkey = builtins.readFile ../../secrets/recipients/wintermute.pub;
        }
      ];
      extraEncryptionPubkeys = [ (builtins.readFile ../../secrets/recipients/recovery.pub) ];
    };
  };
}

{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  publicKey = ../.. + "/secrets/public-keys/${config.networking.hostName}.pub";
  masterKeys = ../.. + "/secrets/master-keys";
  macRecipients = builtins.attrNames (
    lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix "-pq.pub" name) (
      if builtins.pathExists masterKeys then builtins.readDir masterKeys else { }
    )
  );
  recoveryKey = masterKeys + "/recovery.pub";
  readRecipient = path: lib.trim (builtins.readFile path);
in
{
  # Both upstream modules support NixOS and Darwin.
  imports = [
    inputs.agenix.nixosModules.default
    inputs.agenix-rekey.nixosModules.default
  ];
  environment.systemPackages = [ pkgs.age ];
  age.identityPaths = [ "/var/lib/agenix/key.txt" ];
  age.rekey = {
    agePlugins = [ ]; # Supplied by the operator-platform age wrapper.
    masterIdentities =
      map (name: {
        # Encrypt to every Mac; each operator decrypts with their own local enclave.
        identity = "\"$HOME/.config/agenix/secure-enclave-pq.identity\"";
        pubkey = readRecipient (masterKeys + "/${name}");
      }) macRecipients
      ++ [
        {
          # Encrypt to recovery, but use the local enclave unless recovery is explicitly selected.
          identity = "\"\${AGENIX_RECOVERY_IDENTITY:-$HOME/.config/agenix/secure-enclave-pq.identity}\"";
          pubkey = if builtins.pathExists recoveryKey then readRecipient recoveryKey else null;
        }
      ];
    storageMode = "local";
    localStorageDir = ../.. + "/secrets/rekeyed/${config.networking.hostName}";
    hostPubkey = lib.mkIf (builtins.pathExists publicKey) publicKey;
  };
  assertions = [
    {
      assertion =
        config.age.secrets == { }
        || (
          builtins.pathExists publicKey
          && macRecipients != [ ]
          && builtins.all (
            name: lib.hasPrefix "age1tagpq1" (readRecipient (masterKeys + "/${name}"))
          ) macRecipients
          && builtins.pathExists recoveryKey
          && lib.hasPrefix "age1pq1" (readRecipient recoveryKey)
        );
      message = "Enroll PQ Mac recipients (*-pq.pub) and recovery.pub under secrets/master-keys/, and bootstrap the host public key before declaring secrets.";
    }
  ];
}

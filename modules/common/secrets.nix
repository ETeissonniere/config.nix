{
  config,
  inputs,
  hostName,
  lib,
  options,
  pkgs,
  ...
}:
let
  isDarwin = options ? environment.darwinConfig;
  readRecipient =
    name:
    let
      recipient = lib.removeSuffix "\n" (builtins.readFile (../../secrets/recipients + "/${name}.pub"));
    in
    assert lib.assertMsg (
      lib.hasPrefix "age1pq1" recipient || lib.hasPrefix "age1tagpq1" recipient
    ) "The ${name} age recipient must be post-quantum.";
    recipient;
in
{
  config = {
    age = {
      rekey = {
        # A first activation without secrets does not need a registered recipient.
        hostPubkey = lib.mkIf (config.age.secrets != { }) (readRecipient hostName);
        # Source secrets use Wintermute's master key. hostPubkey selects the
        # recipient when a secret is rekeyed for a host.
        masterIdentities = [
          {
            # The CLI reads the identity file outside the Nix store.
            identity = "\"\${AGENIX_IDENTITY:-$HOME/.config/age/identity.key}\"";
            # Only the public key is stored in the repository.
            pubkey = readRecipient "wintermute";
          }
        ];
        extraEncryptionPubkeys = [ (readRecipient "recovery") ];
        storageMode = "local";
        localStorageDir = inputs.self.outPath + "/secrets/rekeyed/${hostName}";
      };
    }
    // lib.optionalAttrs (!isDarwin) {
      ageBin = "${pkgs.age}/bin/age";
      identityPaths = [ "/persist/agenix/${hostName}.key" ];
    };
  }
  // lib.optionalAttrs (!isDarwin) {
    environment.systemPackages = lib.mkBefore [ pkgs.age ];
    systemd.tmpfiles.rules = lib.mkBefore [ "d /persist/agenix 0700 root root -" ];
  };
}

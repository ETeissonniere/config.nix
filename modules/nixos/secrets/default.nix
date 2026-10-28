{
  inputs,
  hostName,
  lib,
  pkgs,
  ...
}:
let
  readRecipient =
    name:
    let
      recipient = lib.removeSuffix "\n" (
        builtins.readFile (../../../secrets/recipients + "/${name}.pub")
      );
    in
    assert lib.assertMsg (
      lib.hasPrefix "age1pq1" recipient || (name == "wintermute" && lib.hasPrefix "age1tagpq1" recipient)
    ) "The ${name} age recipient must be post-quantum.";
    recipient;
in
{
  imports = [
    inputs.agenix.nixosModules.default
    inputs.agenix-rekey.nixosModules.default
  ];

  age = {
    ageBin = "${pkgs.age}/bin/age";
    identityPaths = [ "/persist/agenix/${hostName}.key" ];
    rekey = {
      hostPubkey = readRecipient hostName;
      masterIdentities = [
        {
          # Expanded by the CLI, keeping private keys outside the Nix store.
          identity = "\"\${AGENIX_IDENTITY:-$HOME/.config/age/identity.key}\"";
          pubkey = readRecipient "wintermute";
        }
      ];
      extraEncryptionPubkeys = [ (readRecipient "recovery") ];
      storageMode = "local";
      localStorageDir = inputs.self.outPath + "/secrets/rekeyed/${hostName}";
    };
  };

  environment.systemPackages = [ pkgs.age ];
  systemd.tmpfiles.rules = [ "d /persist/agenix 0700 root root -" ];
}

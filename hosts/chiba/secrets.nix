{
  config,
  inputs,
  pkgs,
  ...
}:
{
  imports = [ inputs.agenix.nixosModules.default ];

  age = {
    ageBin = "${pkgs.age}/bin/age";
    # This private key is generated on chiba and never copied into the Nix store.
    identityPaths = [ "/persist/agenix/chiba.key" ];
    secrets = {
      pocket-id-encryption-key = {
        file = ../../secrets/chiba/pocket-id-encryption-key.age;
        path = "${config.age.secretsMountPoint}/services/pocket-id/encryption-key";
        symlink = false;
      };
      caddy-environment = {
        file = ../../secrets/chiba/caddy-environment.age;
        path = "${config.age.secretsMountPoint}/services/reverse-proxy/caddy.env";
        symlink = false;
      };
    };
  };
  environment.systemPackages = [ pkgs.age ];
  systemd.tmpfiles.rules = [ "d /persist/agenix 0700 root root -" ];
}

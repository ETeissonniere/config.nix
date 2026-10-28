{
  config,
  inputs,
  ...
}:
{
  imports = [ inputs.self.nixosModules.secrets ];

  age.secrets = {
    pocket-id-encryption-key = {
      rekeyFile = ../../secrets/chiba/pocket-id-encryption-key.age;
      path = "${config.age.secretsMountPoint}/services/pocket-id/encryption-key";
      symlink = false;
    };
    caddy-environment = {
      rekeyFile = ../../secrets/chiba/caddy-environment.age;
      path = "${config.age.secretsMountPoint}/services/reverse-proxy/caddy.env";
      symlink = false;
    };
  };
}

{
  config,
  ...
}:
{
  age.secrets = {
    nas-backup-creds.rekeyFile = ../../secrets/chiba/nas-backup-creds.age;
    restic-password.rekeyFile = ../../secrets/chiba/restic-password.age;
    fogline-environment = {
      rekeyFile = ../../secrets/chiba/fogline-environment.age;
      path = "${config.age.secretsMountPoint}/services/fogline/calendar.env";
      symlink = false;
    };
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

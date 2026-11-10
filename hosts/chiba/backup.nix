{ config, ... }:
{
  services.nas-backups = {
    # personal_folder of the backup user, not my actual user
    nasShare = "//gollum.local/personal_folder";
    nasCredentials = config.age.secrets.nas-backup-creds.path;
    jobs.pocket-id = {
      encryptionKeyFile = config.age.secrets.restic-password.path;
      paths = [ "/persist/pocket-id/var/lib/pocket-id" ];
      stopService = "container@pocket-id.service";
    };
  };
}

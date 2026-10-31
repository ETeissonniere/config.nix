{ config, ... }:
{
  containers.pocket-id = {
    limits = {
      MemoryMax = "512M";
      TasksMax = 256;
    };
    ephemeral = true;
    privateNetwork = false;
    privateUsers = "no";
    persistence = {
      directory = "/persist/pocket-id";
      directories = [
        "/var/lib/pocket-id"
      ];
    };
    bindMounts."/run/secrets" = {
      hostPath = builtins.dirOf config.age.secrets.pocket-id-encryption-key.path;
      isReadOnly = true;
    };
    config = { pkgs, ... }: {
      networking.firewall.enable = false;

      services.pocket-id = {
        enable = true;
        credentials.ENCRYPTION_KEY = "/run/secrets/encryption-key";
        settings = {
          APP_URL = "https://auth.teiss.org";
          HOST = "127.0.0.1";
          PORT = 1411;
          ACTORS_HOST = "127.0.0.1";
          TRUST_PROXY = true;
          DB_CONNECTION_STRING = "/var/lib/pocket-id/pocket-id.db";
          UI_CONFIG_DISABLED = true;
          APP_NAME = "B&E Auth";
          HOME_PAGE_URL = "/settings/apps";
          ALLOW_USER_SIGNUPS = "disabled";
          EMAIL_VERIFICATION = "disabled";
          WEBAUTHN_USER_VERIFICATION = "required";
          WEBAUTHN_ALLOW_SYNCED_PASSKEYS = true;
          AUTO_CREATE_OIDC_CLIENT_SECRET = true;
          ANALYTICS_DISABLED = true;
          VERSION_CHECK_DISABLED = true;
        };
      };
      environment.systemPackages = [ pkgs.pocket-id ];

      system.stateVersion = "26.05";
    };
  };

  # Reload systemd credentials when the encrypted secret changes.
  systemd.services."container@pocket-id".restartTriggers = [
    config.age.secrets.pocket-id-encryption-key.file
  ];
}

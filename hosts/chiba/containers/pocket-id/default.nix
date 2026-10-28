{ ... }:
{
  containers.pocket-id = {
    ephemeral = true;
    privateNetwork = false;
    privateUsers = "no";
    persistence = {
      directory = "/persist/pocket-id";
      directories = [
        "/var/lib/pocket-id"
        "/var/lib/pocket-id-secrets"
      ];
    };
    config = { lib, pkgs, ... }: {
      networking.firewall.enable = false;

      services.pocket-id = {
        enable = true;
        credentials.ENCRYPTION_KEY = "/var/lib/pocket-id-secrets/encryption-key";
        settings = {
          APP_URL = "https://id.teiss.org";
          HOST = "127.0.0.1";
          PORT = 1411;
          ACTORS_HOST = "127.0.0.1";
          TRUST_PROXY = true;
          DB_CONNECTION_STRING = "/var/lib/pocket-id/pocket-id.db";
          UI_CONFIG_DISABLED = true;
          APP_NAME = "B&E Auth";
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

      systemd.services.pocket-id-secrets = {
        requiredBy = [ "pocket-id.service" ];
        before = [ "pocket-id.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          StateDirectory = "pocket-id-secrets";
          StateDirectoryMode = "0700";
          UMask = "0077";
        };
        script = ''
          file=/var/lib/pocket-id-secrets/encryption-key
          if [ ! -s "$file" ]; then
            temporary=$(mktemp "$file.XXXXXX")
            ${lib.getExe pkgs.openssl} rand -hex 32 | tr -d '\n' > "$temporary"
            mv "$temporary" "$file"
          fi
        '';
      };

      system.stateVersion = "26.05";
    };
  };

  systemd.services."container@pocket-id".serviceConfig = {
    MemoryHigh = "384M";
    MemoryMax = "512M";
    TasksMax = 256;
  };
}

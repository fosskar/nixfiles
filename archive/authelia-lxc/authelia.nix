{ config, inputs, ... }:
{
  services.authelia.instances.main = {
    enable = true;

    # systemd credentials approach
    secrets.manual = true;
    environmentVariables = {
      AUTHELIA_IDENTITY_VALIDATION_RESET_PASSWORD_JWT_SECRET_FILE = "%d/jwtSecretFile";
      AUTHELIA_STORAGE_ENCRYPTION_KEY_FILE = "%d/storageEncryptionKeyFile";
      AUTHELIA_SESSION_SECRET_FILE = "%d/sessionSecretFile";
    };

    # direct file approach (commented out)
    #secrets = {
    #  jwtSecretFile = config.age.secrets.jwt-secret.path;
    #  storageEncryptionKeyFile = config.age.secrets.storage-encryption-key.path;
    #  sessionSecretFile = config.age.secrets.session-secret.path;
    #};

    settings = {
      theme = "auto";

      webauthn = {
        enable_passkey_login = true;
      };

      server.endpoints.authz.forward-auth.implementation = "ForwardAuth";

      authentication_backend.file.path = "${inputs.nixsecrets}/agenix/nixinfra/authelia/users.yaml";

      access_control = {
        default_policy = "deny";
        rules = [
          {
            domain = "*.smonoscr.me";
            policy = "one_factor";
          }
        ];
      };

      storage.local.path = "/var/lib/authelia-main/db.sqlite3";

      session = {
        cookies = [
          {
            domain = "simonoscar.me";
            authelia_url = "https://auth.simonoscar.me";
          }
        ];
      };

      notifier.filesystem.filename = "/var/lib/authelia-main/notification.txt";
    };
  };

  # systemd credentials - comment out if using direct file approach
  systemd.services.authelia-main.serviceConfig.LoadCredential = [
    "jwtSecretFile:${config.age.secrets.jwt-secret.path}"
    "storageEncryptionKeyFile:${config.age.secrets.storage-encryption-key.path}"
    "sessionSecretFile:${config.age.secrets.session-secret.path}"
  ];

  networking.firewall.allowedTCPPorts = [ 9091 ];
}

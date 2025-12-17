{ config, ... }:
{
  services.vaultwarden = {
    enable = true;
    dbBackend = "postgresql";
    configurePostgres = true;

    environmentFile = config.sops.secrets."vaultwarden.env".path;

    config = {
      # server settings
      DOMAIN = "https://vault.osscar.me";
      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 8222;

      # security settings
      SIGNUPS_ALLOWED = false;
      INVITATIONS_ALLOWED = true;
      SHOW_PASSWORD_HINT = false;

      # admin panel (token in environmentFile)
      # ADMIN_TOKEN is set via environmentFile for security
    };
  };
}

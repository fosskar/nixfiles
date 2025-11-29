{ config, ... }:
{
  services.vaultwarden = {
    enable = true;
    dbBackend = "sqlite";
    #backupDir = "";

    environmentFile = config.sops.secrets."vaultwarden.env".path;

    config = {
      # server settings
      DOMAIN = "https://vault.osscar.me";
      ROCKET_ADDRESS = "10.0.0.109";
      ROCKET_PORT = 8222;

      # security settings
      SIGNUPS_ALLOWED = false;
      INVITATIONS_ALLOWED = true;
      SHOW_PASSWORD_HINT = false;

      SSO_ONLY = false;
      SSO_SIGNUPS_MATCH_EMAIL = true;
      SSO_AUTHORITY = "https://auth.simonoscar.me";
      SSO_PKCE = true;
      SSO_CLIENT_ID = config.sops.secrets."vaultwarden-oidc-client-id".path;
      SSO_CLIENT_SECRET = config.sops.secrets."vaultwarden-oidc-client-secret".path;

      # admin panel (token in environmentFile)
      # ADMIN_TOKEN is set via environmentFile for security
    };
  };

  networking.firewall.allowedTCPPorts = [
    8222 # web vault
  ];
}

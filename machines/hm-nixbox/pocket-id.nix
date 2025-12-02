{
  config,
  ...
}:
{
  services.pocket-id = {
    enable = true;
    environmentFile = config.sops.secrets."pocket-id.env".path;
    settings = {
      APP_URL = "https://auth.simonoscar.me";
      TRUST_PROXY = true;
      ANALYTICS_DISABLED = true;
      KEYS_STORAGE = "database";
      LOG_LEVEL = "debug";
    };
  };

  networking.firewall.allowedTCPPorts = [
    1411
  ];
}

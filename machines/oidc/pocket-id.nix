{
  config,
  ...
}:
{
  services.pocket-id = {
    enable = true;
    environmentFile = config.age.secrets.envs.path;
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

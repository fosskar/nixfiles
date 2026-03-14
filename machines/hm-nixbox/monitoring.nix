{
  config,
  ...
}:
{
  imports = [
    ../../modules/monitoring
  ];

  # machine-specific beszel config
  systemd.services.beszel-agent.unitConfig.RequiresMountsFor = [ "/tank" ];

  services.beszel.agent.environmentFile = config.sops.secrets."beszel.env".path;

  # grafana alerting -> ntfy
  systemd.services.grafana.serviceConfig.EnvironmentFile =
    config.clan.core.vars.generators.ntfy.files."token-env".path;

  services.grafana.provision.alerting.contactPoints.settings = {
    apiVersion = 1;
    contactPoints = [
      {
        orgId = 1;
        name = "ntfy";
        receivers = [
          {
            uid = "ntfy";
            type = "webhook";
            settings = {
              url = "http://127.0.0.1:8091/grafana";
              httpMethod = "POST";
              authorization_header = "Bearer $__env{NTFY_TOKEN}";
            };
          }
        ];
      }
    ];
  };

  nixfiles.monitoring = {
    beszel = {
      hub.enable = true;
      agent = {
        enable = true;
        sensors = "-nct6798_cputin,-nct6798_auxtin0,-nct6798_auxtin2,-nct6798_auxtin4";
        filesystem = "/persist";
        extraFilesystems = "/nix__Nix,/tank/apps__Apps,/tank/media__Media,/tank/shares__Shares,/tank/backup__Backup";
      };
    };
  };
}

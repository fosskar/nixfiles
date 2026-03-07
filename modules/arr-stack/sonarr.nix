{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixfiles.arr-stack;
  acmeDomain = config.nixfiles.acme.domain;
  serviceDomain = "sonarr.${acmeDomain}";
  bindAddress = "127.0.0.1";
  port = 8989;
  internalUrl = "http://${bindAddress}:${toString port}";
in
{
  config = lib.mkIf cfg.sonarr.enable {
    # --- service ---

    services.sonarr = {
      enable = true;
      openFirewall = false;
      group = "media";
      settings.server.port = port;
    };

    # --- homepage ---

    nixfiles.homepage.entries = lib.mkIf config.services.homepage-dashboard.enable [
      {
        name = "Sonarr";
        category = "Arr Stack";
        icon = "sonarr.svg";
        href = "https://${serviceDomain}";
        siteMonitor = internalUrl;
      }
    ];

    # --- gatus ---

    nixfiles.gatus.endpoints = lib.mkIf config.nixfiles.gatus.enable [
      {
        name = "Sonarr";
        url = "https://${serviceDomain}";
        group = "Arr Stack";
      }
    ];

    # --- nginx ---

    nixfiles.nginx.vhosts.sonarr = {
      inherit port;
      proxy-auth = cfg.authelia.enable;
    };

    # --- backup ---

    clan.core.state.sonarr = {
      folders = [ "/var/backup/sonarr" ];
      preBackupScript = ''
        export PATH=${
          lib.makeBinPath [
            pkgs.sqlite
            pkgs.coreutils
          ]
        }
        mkdir -p /var/backup/sonarr
        sqlite3 /var/lib/sonarr/.config/NzbDrone/sonarr.db ".backup '/var/backup/sonarr/sonarr.db'"
      '';
    };
  };
}

{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixfiles.arr-stack;
  acmeDomain = config.nixfiles.acme.domain;
  serviceDomain = "radarr.${acmeDomain}";
  bindAddress = "127.0.0.1";
  port = 7878;
  internalUrl = "http://${bindAddress}:${toString port}";
in
{
  config = lib.mkIf cfg.radarr.enable {
    # --- service ---

    services.radarr = {
      enable = true;
      openFirewall = false;
      group = "media";
      settings.server.port = port;
    };

    # --- homepage ---

    nixfiles.homepage.entries = lib.mkIf config.services.homepage-dashboard.enable [
      {
        name = "Radarr";
        category = "Arr Stack";
        icon = "radarr.svg";
        href = "https://${serviceDomain}";
        siteMonitor = internalUrl;
      }
    ];

    # --- gatus ---

    nixfiles.gatus.endpoints = lib.mkIf config.nixfiles.gatus.enable [
      {
        name = "Radarr";
        url = "https://${serviceDomain}";
        group = "Arr Stack";
      }
    ];

    # --- nginx ---

    nixfiles.nginx.vhosts.radarr = {
      inherit port;
      proxy-auth = cfg.authelia.enable;
    };

    # --- backup ---

    clan.core.state.radarr = {
      folders = [ "/var/backup/radarr" ];
      preBackupScript = ''
        export PATH=${
          lib.makeBinPath [
            pkgs.sqlite
            pkgs.coreutils
          ]
        }
        mkdir -p /var/backup/radarr
        sqlite3 /var/lib/radarr/.config/Radarr/radarr.db ".backup '/var/backup/radarr/radarr.db'"
      '';
    };
  };
}

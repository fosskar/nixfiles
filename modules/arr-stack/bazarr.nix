{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixfiles.arr-stack;
  acmeDomain = config.nixfiles.acme.domain;
  serviceDomain = "bazarr.${acmeDomain}";
  bindAddress = "127.0.0.1";
  port = 6767;
  internalUrl = "http://${bindAddress}:${toString port}";
in
{
  config = lib.mkIf cfg.bazarr.enable {
    # --- service ---

    services.bazarr = {
      enable = true;
      openFirewall = false;
      group = "media";
      listenPort = port;
    };

    systemd.services.bazarr.serviceConfig.UMask = "0027";

    # --- homepage ---

    nixfiles.homepage.entries = lib.mkIf config.services.homepage-dashboard.enable [
      {
        name = "Bazarr";
        category = "Arr Stack";
        icon = "bazarr.svg";
        href = "https://${serviceDomain}";
        siteMonitor = internalUrl;
      }
    ];

    # --- gatus ---

    nixfiles.gatus.endpoints = lib.mkIf config.nixfiles.gatus.enable [
      {
        name = "Bazarr";
        url = "https://${serviceDomain}";
        group = "Arr Stack";
      }
    ];

    # --- nginx ---

    nixfiles.nginx.vhosts.bazarr = {
      inherit port;
      proxy-auth = cfg.authelia.enable;
    };

    # --- backup ---

    clan.core.state.bazarr = {
      folders = [ "/var/backup/bazarr" ];
      preBackupScript = ''
        export PATH=${
          lib.makeBinPath [
            pkgs.sqlite
            pkgs.coreutils
          ]
        }
        mkdir -p /var/backup/bazarr
        sqlite3 /var/lib/bazarr/db/bazarr.db ".backup '/var/backup/bazarr/bazarr.db'"
      '';
    };
  };
}

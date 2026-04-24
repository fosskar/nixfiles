{
  flake.modules.nixos.arrStack =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      acmeDomain = "nx3.eu";
      serviceDomain = "bazarr.${acmeDomain}";
      bindAddress = "127.0.0.1";
      port = 6767;
      internalUrl = "http://${bindAddress}:${toString port}";
    in
    {
      config = {
        # --- service ---

        services.bazarr = {
          enable = true;
          openFirewall = false;
          group = "media";
          listenPort = port;
        };

        systemd.services.bazarr.serviceConfig.UMask = "0027";

        # --- homepage ---

        services.homepage-dashboard.serviceGroups."Arr Stack" =
          lib.mkIf config.services.homepage-dashboard.enable
            [
              {
                "Bazarr" = {
                  href = "https://${serviceDomain}";
                  icon = "bazarr.svg";
                  siteMonitor = internalUrl;
                };
              }
            ];

        # --- gatus ---

        services.gatus.settings.endpoints = lib.mkIf config.services.gatus.enable [
          {
            name = "Bazarr";
            url = internalUrl;
            group = "Arr Stack";
            enabled = true;
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
            alerts = [ { type = "ntfy"; } ];
          }
        ];

        # --- caddy ---

        services.caddy.virtualHosts."bazarr.nx3.eu".extraConfig = ''
          ${lib.optionalString (config.services.authelia.instances.main.enable or false) "import authelia"}
          reverse_proxy 127.0.0.1:${toString port}
        '';

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
    };
}

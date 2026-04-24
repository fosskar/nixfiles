{
  flake.modules.nixos.arrStack =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      mediaRoot = "/tank/media";
      acmeDomain = "nx3.eu";
      serviceDomain = "sabnzbd.${acmeDomain}";
      bindAddress = "127.0.0.1";
      port = 8085;
      internalUrl = "http://${bindAddress}:${toString port}";
    in
    {
      config = {
        # --- service ---

        clan.core.vars.generators.sabnzbd = {
          files.secret = {
            secret = true;
            owner = "sabnzbd";
          };
          prompts.config = {
            description = "sabnzbd secret ini (api keys, server credentials)";
            type = "multiline";
            persist = true;
          };
          script = "cat $prompts/config > $out/secret";
        };

        services.sabnzbd = {
          enable = true;
          openFirewall = false;
          group = "media";
          allowConfigWrite = true;
          secretFiles = [ config.clan.core.vars.generators.sabnzbd.files.secret.path ];
          settings = {
            misc = {
              inherit port;
              host_whitelist = "nixbox, sabnzbd.nx3.eu";
              download_dir = "${mediaRoot}/downloads/incomplete";
              complete_dir = "${mediaRoot}/downloads/complete";
              permissions = "770";
            };
            categories = {
              movies.name = "movies";
              tv.name = "tv";
              music.name = "music";
              books.name = "books";
              podcasts = {
                name = "podcasts";
                script = "Default";
              };
              "*" = {
                name = "*";
                pp = 3;
                script = "Default";
              };
            };
          };
        };

        # --- homepage ---

        services.homepage-dashboard.serviceGroups."Arr Stack" =
          lib.mkIf config.services.homepage-dashboard.enable
            [
              {
                "SABnzbd" = {
                  href = "https://${serviceDomain}";
                  icon = "sabnzbd.svg";
                  siteMonitor = internalUrl;
                };
              }
            ];

        # --- gatus ---

        services.gatus.settings.endpoints = lib.mkIf config.services.gatus.enable [
          {
            name = "SABnzbd";
            url = internalUrl;
            group = "Arr Stack";
            enabled = true;
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
            alerts = [ { type = "ntfy"; } ];
          }
        ];

        # --- caddy ---

        services.caddy.virtualHosts."sabnzbd.nx3.eu".extraConfig = ''
          ${lib.optionalString (config.services.authelia.instances.main.enable or false) "import authelia"}
          reverse_proxy 127.0.0.1:${toString port}
        '';

        # --- backup ---

        clan.core.state.sabnzbd = {
          folders = [ "/var/backup/sabnzbd" ];
          preBackupScript = ''
            export PATH=${
              lib.makeBinPath [
                pkgs.sqlite
                pkgs.coreutils
              ]
            }
            mkdir -p /var/backup/sabnzbd
            sqlite3 /var/lib/sabnzbd/sabnzbd.db ".backup '/var/backup/sabnzbd/sabnzbd.db'"
          '';
        };
      };
    };
}

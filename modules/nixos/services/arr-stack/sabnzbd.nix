{
  flake.modules.nixos.arrStack =
    {
      config,
      domains,
      lib,
      pkgs,
      ...
    }:
    let
      mediaRoot = "/tank/media";
      serviceName = "sabnzbd";
      localHost = "${serviceName}.${domains.local}";
      listenAddress = "127.0.0.1";
      listenPort = 8085;
      listenUrl = "http://${listenAddress}:${toString listenPort}";
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
              port = listenPort;
              host_whitelist = "nixbox, ${localHost}";
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
                  href = "https://${localHost}";
                  icon = "sabnzbd.svg";
                  siteMonitor = listenUrl;
                };
              }
            ];

        # --- gatus ---

        services.gatus.settings.endpoints = lib.mkIf config.services.gatus.enable [
          {
            name = "SABnzbd";
            url = listenUrl;
            group = "Arr Stack";
            enabled = true;
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
            alerts = [ { type = "ntfy"; } ];
          }
        ];

        # --- caddy ---

        services.caddy.virtualHosts.${localHost}.extraConfig = ''
          ${lib.optionalString (config.services.authelia.instances.main.enable or false) "import authelia"}
          reverse_proxy ${listenUrl}
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

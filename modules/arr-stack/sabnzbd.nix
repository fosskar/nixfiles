{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixfiles.arr-stack;
  acmeDomain = config.nixfiles.caddy.domain;
  serviceDomain = "sabnzbd.${acmeDomain}";
  bindAddress = "127.0.0.1";
  port = 8085;
  internalUrl = "http://${bindAddress}:${toString port}";
in
{
  config = lib.mkIf cfg.sabnzbd.enable {
    # --- service ---

    services.sabnzbd = {
      enable = true;
      openFirewall = false;
      group = "media";
      allowConfigWrite = true;
      secretFiles = [ config.sops.secrets."sabnzbd".path ];
      settings = {
        misc = {
          inherit port;
          host_whitelist = "hm-nixbox, sabnzbd.osscar.me";
          download_dir = "${cfg.mediaRoot}/downloads/incomplete";
          complete_dir = "${cfg.mediaRoot}/downloads/complete";
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

    nixfiles.homepage.entries = lib.mkIf config.services.homepage-dashboard.enable [
      {
        name = "SABnzbd";
        category = "Arr Stack";
        icon = "sabnzbd.svg";
        href = "https://${serviceDomain}";
        siteMonitor = internalUrl;
      }
    ];

    # --- gatus ---

    nixfiles.gatus.endpoints = lib.mkIf config.nixfiles.gatus.enable [
      {
        name = "SABnzbd";
        url = "https://${serviceDomain}";
        group = "Arr Stack";
      }
    ];

    # --- caddy ---

    nixfiles.caddy.vhosts.sabnzbd = {
      inherit port;
      proxy-auth = cfg.authelia.enable;
    };

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
}

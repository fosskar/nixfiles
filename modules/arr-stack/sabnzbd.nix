{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixfiles.arr-stack;
  port = 8085;
in
{
  config = lib.mkIf cfg.sabnzbd.enable {
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

    systemd.services.sabnzbd.serviceConfig.UMask = "0027";

    nixfiles.nginx.vhosts.sabnzbd = {
      inherit port;
      proxy-auth = cfg.authelia.enable;
    };

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

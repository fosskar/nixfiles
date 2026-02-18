{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixfiles.arr-stack;
  port = 7878;
in
{
  config = lib.mkIf cfg.radarr.enable {
    services.radarr = {
      enable = true;
      openFirewall = false;
      group = "media";
      settings.server.port = port;
    };

    nixfiles.nginx.vhosts.radarr = {
      inherit port;
      proxy-auth = cfg.authelia.enable;
    };

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

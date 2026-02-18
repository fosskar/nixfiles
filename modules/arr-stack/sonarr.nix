{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixfiles.arr-stack;
  port = 8989;
in
{
  config = lib.mkIf cfg.sonarr.enable {
    services.sonarr = {
      enable = true;
      openFirewall = false;
      group = "media";
      settings.server.port = port;
    };

    nixfiles.nginx.vhosts.sonarr = {
      inherit port;
      proxy-auth = cfg.authelia.enable;
    };

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

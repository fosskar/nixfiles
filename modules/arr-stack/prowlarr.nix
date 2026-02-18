{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixfiles.arr-stack;
  port = 9696;
in
{
  config = lib.mkIf cfg.prowlarr.enable {
    services.prowlarr = {
      enable = true;
      openFirewall = false;
      settings.server.port = port;
    };

    nixfiles.nginx.vhosts.prowlarr = {
      inherit port;
      proxy-auth = cfg.authelia.enable;
    };

    clan.core.state.prowlarr = {
      folders = [ "/var/backup/prowlarr" ];
      preBackupScript = ''
        export PATH=${
          lib.makeBinPath [
            pkgs.sqlite
            pkgs.coreutils
          ]
        }
        mkdir -p /var/backup/prowlarr
        sqlite3 /var/lib/private/prowlarr/prowlarr.db ".backup '/var/backup/prowlarr/prowlarr.db'"
      '';
    };
  };
}

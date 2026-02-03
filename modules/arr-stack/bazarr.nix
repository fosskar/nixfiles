{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixfiles.arr-stack;
  port = 6767;
in
{
  config = lib.mkIf cfg.bazarr.enable {
    services.bazarr = {
      enable = true;
      openFirewall = false;
      group = "media";
      listenPort = port;
    };

    systemd.services.bazarr.serviceConfig.UMask = "0027";

    nixfiles.nginx.vhosts.bazarr = {
      inherit port;
      proxy-auth = cfg.authelia.enable;
    };

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

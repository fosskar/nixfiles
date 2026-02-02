{
  config,
  lib,
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
        sqlite-backup /var/lib/bazarr/db/bazarr.db /var/backup/bazarr/bazarr.db
      '';
    };
  };
}

{
  config,
  lib,
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

    systemd.services.prowlarr.serviceConfig.UMask = "0027";

    nixfiles.nginx.vhosts.prowlarr = {
      inherit port;
      proxy-auth = cfg.authelia.enable;
    };

    clan.core.state.prowlarr = {
      folders = [ "/var/backup/prowlarr" ];
      preBackupScript = ''
        sqlite-backup /var/lib/private/prowlarr/prowlarr.db /var/backup/prowlarr/prowlarr.db
      '';
    };
  };
}

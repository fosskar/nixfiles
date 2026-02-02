{
  config,
  lib,
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

    systemd.services.sonarr.serviceConfig.UMask = "0027";

    nixfiles.nginx.vhosts.sonarr = {
      inherit port;
      proxy-auth = cfg.authelia.enable;
    };

    clan.core.state.sonarr = {
      folders = [ "/var/backup/sonarr" ];
      preBackupScript = ''
        sqlite-backup /var/lib/sonarr/.config/NzbDrone/sonarr.db /var/backup/sonarr/sonarr.db
      '';
    };
  };
}

{
  config,
  lib,
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

    systemd.services.radarr.serviceConfig.UMask = "0027";

    nixfiles.nginx.vhosts.radarr = {
      inherit port;
      proxy-auth = cfg.authelia.enable;
    };

    clan.core.state.radarr = {
      folders = [ "/var/backup/radarr" ];
      preBackupScript = ''
        sqlite-backup /var/lib/radarr/.config/Radarr/radarr.db /var/backup/radarr/radarr.db
      '';
    };
  };
}

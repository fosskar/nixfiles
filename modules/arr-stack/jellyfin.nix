{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixfiles.arr-stack;
  port = 8096;
in
{
  config = lib.mkIf cfg.jellyfin.enable {
    services.jellyfin = {
      enable = true;
      openFirewall = false;
      group = "media";
      hardwareAcceleration = lib.mkIf (cfg.jellyfin.hwAccel.type != null) {
        inherit (cfg.jellyfin.hwAccel) device;
        inherit (cfg.jellyfin.hwAccel) type;
      };
    };

    users.users.jellyfin.extraGroups = [
      "render"
      "video"
    ];

    systemd.services.jellyfin.environment = lib.mkIf (cfg.jellyfin.hwAccel.type == "qsv") {
      LIBVA_DRIVER_NAME = "iHD";
    };

    environment.systemPackages = with pkgs; [
      jellyfin
      jellyfin-web
      jellyfin-ffmpeg
    ];

    # no proxy-auth - jellyfin has built-in auth
    nixfiles.nginx.vhosts.jellyfin = {
      inherit port;
    };

    clan.core.state.jellyfin = {
      folders = [ "/var/backup/jellyfin" ];
      preBackupScript = ''
        sqlite-backup /var/lib/jellyfin/data/jellyfin.db /var/backup/jellyfin/jellyfin.db
      '';
    };
  };
}

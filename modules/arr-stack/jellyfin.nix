{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixfiles.arr-stack;
  acmeDomain = config.nixfiles.caddy.domain;
  serviceDomain = "jellyfin.${acmeDomain}";
  bindAddress = "127.0.0.1";
  port = 8096;
  internalUrl = "http://${bindAddress}:${toString port}";
in
{
  config = lib.mkIf cfg.jellyfin.enable {
    # --- service ---

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

    environment.systemPackages = with pkgs; [
      jellyfin
      jellyfin-web
      jellyfin-ffmpeg
    ];

    # --- homepage ---

    nixfiles.homepage.entries = lib.mkIf config.services.homepage-dashboard.enable [
      {
        name = "Jellyfin";
        category = "Media";
        icon = "jellyfin.png";
        href = "https://${serviceDomain}";
        siteMonitor = internalUrl;
      }
    ];

    # --- gatus ---

    nixfiles.gatus.endpoints = lib.mkIf config.nixfiles.gatus.enable [
      {
        name = "Jellyfin";
        url = internalUrl;
        group = "Media";
      }
    ];

    # --- caddy ---

    # no proxy-auth - jellyfin has built-in auth
    nixfiles.caddy.vhosts.jellyfin = {
      inherit port;
    };

    # --- backup ---

    clan.core.state.jellyfin = {
      folders = [ "/var/backup/jellyfin" ];
      preBackupScript = ''
        export PATH=${
          lib.makeBinPath [
            pkgs.sqlite
            pkgs.coreutils
          ]
        }
        mkdir -p /var/backup/jellyfin
        sqlite3 /var/lib/jellyfin/data/jellyfin.db ".backup '/var/backup/jellyfin/jellyfin.db'"
      '';
    };

    # --- systemd ---

    systemd.services.jellyfin.environment = lib.mkIf (cfg.jellyfin.hwAccel.type == "qsv") {
      LIBVA_DRIVER_NAME = "iHD";
    };
  };
}

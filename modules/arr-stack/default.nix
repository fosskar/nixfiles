{
  config,
  lib,
  mylib,
  ...
}:
let
  cfg = config.nixfiles.arr-stack;
in
{
  imports = mylib.scanPaths ./. { };

  options.nixfiles.arr-stack = {
    mediaRoot = lib.mkOption {
      type = lib.types.str;
      default = "/tank/media";
      description = "root path for media directories";
    };

    authelia.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "protect arr services with authelia forward-auth";
    };

    sabnzbd.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "enable sabnzbd download client";
    };

    prowlarr.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "enable prowlarr indexer";
    };

    sonarr.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "enable sonarr tv manager";
    };

    radarr.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "enable radarr movie manager";
    };

    bazarr.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "enable bazarr subtitle manager";
    };

    jellyfin = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "enable jellyfin media server";
      };
      hwAccel = {
        device = lib.mkOption {
          type = lib.types.str;
          default = "/dev/dri/renderD128";
          description = "hardware acceleration device path";
        };
        type = lib.mkOption {
          type = lib.types.nullOr (
            lib.types.enum [
              "qsv"
              "vaapi"
              "nvenc"
            ]
          );
          default = "qsv";
          description = "hardware acceleration type (null to disable)";
        };
      };
    };

    jellyseerr.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "enable jellyseerr request management";
    };

    recyclarr.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "enable recyclarr trash guides sync";
    };
  };

  config = {
    # media group for shared access
    users.groups.media = { };

    # media directories
    systemd.tmpfiles.rules = [
      "d ${cfg.mediaRoot}/books 0775 root media -"
      "d ${cfg.mediaRoot}/movies 0775 root media -"
      "d ${cfg.mediaRoot}/music 0775 root media -"
      "d ${cfg.mediaRoot}/podcasts 0775 root media -"
      "d ${cfg.mediaRoot}/tv 0775 root media -"
      "d ${cfg.mediaRoot}/downloads 0775 root media -"
      "d ${cfg.mediaRoot}/downloads/incomplete 0775 root media -"
      "d ${cfg.mediaRoot}/downloads/complete 0775 root media -"
    ];

    # authelia access control rules for arr services
    services.authelia.instances.main.settings.access_control.rules = lib.mkIf cfg.authelia.enable [
      # bypass API endpoints for arr service communication
      {
        domain = [
          "sonarr.*"
          "radarr.*"
          "prowlarr.*"
          "bazarr.*"
          "sabnzbd.*"
        ];
        policy = "bypass";
        resources = [
          "^/api.*"
          "^/feed.*"
        ];
      }
      # require 2FA for web UI access
      {
        domain = [
          "sonarr.*"
          "radarr.*"
          "prowlarr.*"
          "bazarr.*"
          "sabnzbd.*"
        ];
        policy = "two_factor";
      }
    ];
  };
}

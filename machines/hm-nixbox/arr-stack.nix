{
  pkgs,
  config,
  lib,
  ...
}:
{
  nixfiles.nginx.vhosts = {
    jellyfin.port = 8096; # no port option
    jellyseerr.port = config.services.jellyseerr.port;
    audiobookshelf.port = config.services.audiobookshelf.port;
    prowlarr.port = config.services.prowlarr.settings.server.port;
    sonarr.port = config.services.sonarr.settings.server.port;
    radarr.port = config.services.radarr.settings.server.port;
    lidarr.port = config.services.lidarr.settings.server.port;
    readarr.port = config.services.readarr.settings.server.port;
    sabnzbd.port = 8080; # no port option
  };

  users = {

    groups.media = { };

    users.jellyfin = {
      extraGroups = [
        "render"
        "video"
      ];
    };
  };

  services = {
    # download client
    sabnzbd = {
      enable = true;
      openFirewall = false;
      group = "media";
    };

    # indexer
    prowlarr = {
      enable = true;
      openFirewall = false;
      settings.server.port = 9696;
    };

    # media managers
    sonarr = {
      enable = true;
      openFirewall = false;
      settings.server.port = 8989;
      group = "media";
    };

    radarr = {
      enable = true;
      openFirewall = false;
      settings.server.port = 7878;
      group = "media";
    };

    lidarr = {
      enable = true;
      openFirewall = false;
      settings.server.port = 8686;
      group = "media";
    };

    readarr = {
      enable = true;
      openFirewall = false;
      settings.server.port = 8787;
      group = "media";
    };

    bazarr = {
      enable = true;
      listenPort = 6767;
      openFirewall = false;
      group = "media";
    };

    # request management
    jellyseerr = {
      enable = true;
      port = 5055;
      openFirewall = false;
    };

    jellyfin = {
      enable = true;
      openFirewall = false; # port 8096
      group = "media";
    };

    audiobookshelf = {
      enable = true;
      host = "127.0.0.1";
      port = 13378;
      openFirewall = false;
      group = "media";
    };

    # auto-sync trash guides to sonarr/radarr
    recyclarr = {
      enable = true;
      schedule = "weekly";
      configuration = {
        sonarr.series = {
          base_url = "http://127.0.0.1:${toString config.services.sonarr.settings.server.port}";
          api_key = "!env_var SONARR_API_KEY";
          quality_definition = {
            type = "series";
          };
          delete_old_custom_formats = true;
          include = [
            { template = "sonarr-quality-definition-series"; }
            { template = "sonarr-v4-quality-profile-web-1080p"; }
            { template = "sonarr-v4-custom-formats-web-1080p"; }
          ];
        };
        radarr.movies = {
          base_url = "http://127.0.0.1:${toString config.services.radarr.settings.server.port}";
          api_key = "!env_var RADARR_API_KEY";
          quality_definition = {
            type = "movie";
          };
          delete_old_custom_formats = true;
          include = [
            { template = "radarr-quality-definition-movie"; }
            { template = "radarr-quality-profile-remux-web-1080p"; }
            { template = "radarr-custom-formats-remux-web-1080p"; }
          ];
        };
      };
    };
  };

  # umask for proper file permissions (0027 = 640/750)
  systemd = {
    services = {
      sabnzbd = {
        serviceConfig.UMask = "0027";
        preStart = lib.mkAfter ''
          ${pkgs.gnused}/bin/sed -i 's/^host_whitelist = .*/host_whitelist = hm-nixbox, sabnzbd.osscar.me/' /var/lib/sabnzbd/sabnzbd.ini
        '';
      };
      prowlarr.serviceConfig.UMask = "0027";
      sonarr.serviceConfig.UMask = "0027";
      radarr.serviceConfig.UMask = "0027";
      lidarr.serviceConfig.UMask = "0027";
      readarr.serviceConfig.UMask = "0027";
      bazarr.serviceConfig.UMask = "0027";
      jellyseerr.serviceConfig.UMask = "0027";

      jellyfin.environment.LIBVA_DRIVER_NAME = "iHD";

      recyclarr = {
        serviceConfig.EnvironmentFile = config.sops.secrets."arr-stack.env".path;
        preStart = ''
          ${pkgs.yq-go}/bin/yq -o yaml \
            'with((.. | select(kind == "scalar") | select(tag == "!!str") | select(test("^!env_var .*"))); . = sub("!env_var ", "") | . tag = "!env_var")' \
            /var/lib/recyclarr/config.json > /var/lib/recyclarr/recyclarr.yml
        '';
        serviceConfig.ExecStart = lib.mkForce "${pkgs.recyclarr}/bin/recyclarr sync --config /var/lib/recyclarr/recyclarr.yml";
      };
    };

    # media directories on zfs pool
    tmpfiles.rules = [
      "d /tank/media/books 0775 root media -"
      "d /tank/media/movies 0775 root media -"
      "d /tank/media/music 0775 root media -"
      "d /tank/media/podcasts 0775 root media -"
      "d /tank/media/tv 0775 root media -"
    ];
  };

  environment.systemPackages = with pkgs; [
    jellyfin
    jellyfin-web
    jellyfin-ffmpeg
  ];
}

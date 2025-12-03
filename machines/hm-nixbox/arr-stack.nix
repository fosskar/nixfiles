{ pkgs, ... }:
{
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
  };

  # umask for proper file permissions (0027 = 640/750)
  systemd = {
    services = {
      sabnzbd.serviceConfig.UMask = "0027";
      prowlarr.serviceConfig.UMask = "0027";
      sonarr.serviceConfig.UMask = "0027";
      radarr.serviceConfig.UMask = "0027";
      lidarr.serviceConfig.UMask = "0027";
      readarr.serviceConfig.UMask = "0027";
      bazarr.serviceConfig.UMask = "0027";
      jellyseerr.serviceConfig.UMask = "0027";

      jellyfin.environment.LIBVA_DRIVER_NAME = "iHD";
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

  environment.systemPackages = [
    pkgs.jellyfin
    pkgs.jellyfin-web
    pkgs.jellyfin-ffmpeg
    pkgs.fontconfig
  ];
}

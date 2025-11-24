{ ... }:
{
  # shared user/group for all arr services
  users = {
    users.arr = {
      isSystemUser = true;
      group = "arr";
      uid = 1110; # container 110 -> uid 1110 -> host 101110
    };
    groups.arr = {
      gid = 10000; # maps to host 110000 (storage_shared)
    };
  };

  # prowlarr - indexer manager (central hub for all indexers)
  services.prowlarr = {
    enable = true;
    settings.server.port = 9696;
    openFirewall = true;
  };

  # sonarr - tv show management
  services.sonarr = {
    enable = true;
    settings.server.port = 8989;
    openFirewall = true;
    user = "arr";
    group = "arr";
  };

  # radarr - movie management
  services.radarr = {
    enable = true;
    settings.server.port = 7878;
    openFirewall = true;
    user = "arr";
    group = "arr";
  };

  # lidarr - music management
  services.lidarr = {
    enable = true;
    settings.server.port = 8686;
    openFirewall = true;
    user = "arr";
    group = "arr";
  };

  # readarr - audiobook/ebook management
  services.readarr = {
    enable = true;
    settings.server.port = 8787;
    openFirewall = true;
    user = "arr";
    group = "arr";
  };

  # bazarr - subtitle management
  services.bazarr = {
    enable = true;
    listenPort = 6767;
    openFirewall = true;
    user = "arr";
    group = "arr";
  };

  # jellyseerr - request management ui
  services.jellyseerr = {
    enable = true;
    port = 5055;
    openFirewall = true;
  };

  # set umask for arr services so created files are group-readable
  # umask 0027 = files: 640 (rw-r-----), dirs: 750 (rwxr-x---)
  systemd.services = {
    radarr.serviceConfig.UMask = "0027";
    sonarr.serviceConfig.UMask = "0027";
    lidarr.serviceConfig.UMask = "0027";
    readarr.serviceConfig.UMask = "0027";
  };

  # create media directory structure on boot
  # bind mount from proxmox: /tank/media → /mnt/media
  systemd.tmpfiles.rules = [
    # organized media library directories
    "d /mnt/media/books 0775 arr arr -"
    "d /mnt/media/movies 0775 arr arr -"
    "d /mnt/media/music 0775 arr arr -"
    "d /mnt/media/podcasts 0775 arr arr -"
    "d /mnt/media/tv 0775 arr arr -"
  ];
}

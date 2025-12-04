{ config, pkgs, ... }:
{
  # listen on localhost:8009 instead of port 80
  services.nginx.virtualHosts."localhost" = {
    listen = [{ addr = "127.0.0.1"; port = 8009; }];
  };

  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud32;

    # php opcache settings
    phpOptions."opcache.interned_strings_buffer" = "16";

    #extraApps = {
    #  inherit (config.services.nextcloud.package.packages.apps)
    #    calendar
    #    tasks
    #    ;
    #};
    extraAppsEnable = false;

    autoUpdateApps.enable = false;

    hostName = "localhost";
    config = {
      adminpassFile = config.sops.secrets."admin-password".path;
      adminuser = "admin";

      dbtype = "pgsql";
    };

    database.createLocally = true;

    settings = {
      # tell nextcloud it's behind https proxy
      overwriteprotocol = "https";
      overwrite.cli.url = "https://cloud.osscar.me";
      trusted_proxies = [ "127.0.0.1" ];

      # phone region for validation
      default_phone_region = "DE";

      # maintenance window (3am UTC)
      maintenance_window_start = 3;

      enabledPreviewProviders = [
        "OC\\Preview\\BMP"
        "OC\\Preview\\GIF"
        "OC\\Preview\\JPEG"
        "OC\\Preview\\Krita"
        "OC\\Preview\\MarkDown"
        "OC\\Preview\\MP3"
        "OC\\Preview\\OpenDocument"
        "OC\\Preview\\PNG"
        "OC\\Preview\\TXT"
        "OC\\Preview\\XBitmap"
        "OC\\Preview\\HEIC"
      ];
      trusted_domains = [
        "127.0.0.1"
        "localhost"
        "cloud.osscar.me"
      ];
    };
  };
}

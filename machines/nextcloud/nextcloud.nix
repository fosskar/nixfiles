{ config, pkgs, ... }:
{
  services.nextcloud = {
    enable = false;
    package = pkgs.nextcloud32;

    extraApps = {
      inherit (config.services.nextcloud.package.packages.apps)
        calendar
        tasks
        ;
    };
    extraAppsEnable = true;
    autoUpdateApps.enable = false;
    maxUploadSize = "16G";

    hostName = "nextcloud";
    config = {
      adminpassFile = config.age.secrets.nextcloud-admin-pw.path;
      adminuser = "admin";

      dbtype = "pgsql";
    };
    configureRedis = true;
    database.createLocally = true;

    settings = {
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
        "10.0.0.112"
        "cloud.osscar.me"
        "10.0.0.101"
      ];
    };
  };

  services.nginx.virtualHosts."nextcloud".listen = [
    {
      addr = "10.0.0.112";
      port = 8009;
    }
  ];

  networking.firewall.allowedTCPPorts = [
    8009
  ];
}

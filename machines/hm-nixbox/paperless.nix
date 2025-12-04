{ config, lib, ... }:
{
  services.paperless = {
    enable = true;
    address = "127.0.0.1";
    port = 28981;
    domain = "docs.osscar.me";

    # storage locations (bind mounted from /tank/apps/paperless)
    dataDir = "/tank/apps/paperless/data";
    mediaDir = "/tank/apps/paperless/media";
    consumptionDir = "/tank/apps/paperless/consume";

    # local postgresql, own paperless database
    database.createLocally = true;

    environmentFile = config.sops.secrets."paperless.env".path;

    passwordFile = config.sops.secrets."admin-password".path;

    settings = {
      PAPERLESS_ADMIN_USER = "admin";
      PAPERLESS_OCR_LANGUAGE = "deu+eng"; # english + german
      PAPERLESS_TIME_ZONE = "Europe/Berlin";
      PAPERLESS_TRUSTED_PROXIES = "138.201.155.21,127.0.0.1";

      PAPERLESS_CONSUMER_RECURSIVE = true;
      PAPERLESS_CONSUMER_SUBDIRS_AS_TAGS = true;

      PAPERLESS_CONSUMER_IGNORE_PATTERN = [
        ".DS_STORE/*"
        "desktop.ini"
      ];
      PAPERLESS_OCR_USER_ARGS = {
        optimize = 1;
        pdfa_image_compression = "lossless";
      };
    };
  };
}

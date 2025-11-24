{ config, lib, ... }:
{
  services.paperless = {
    enable = true;
    address = "10.0.0.108";
    port = 28981;
    domain = "docs.osscar.me";

    # storage locations (bind mounted from /tank/apps/paperless)
    dataDir = "/mnt/paperless/data";
    mediaDir = "/mnt/paperless/media";
    consumptionDir = "/mnt/consume";

    # local postgresql database
    database.createLocally = true;

    environmentFile = config.age.secrets.paperless-envs.path;
    # admin password from secrets
    passwordFile = config.age.secrets.paperless-admin-password.path;

    settings = {
      PAPERLESS_ADMIN_USER = "admin";
      PAPERLESS_OCR_LANGUAGE = "deu+eng"; # english + german
      PAPERLESS_TIME_ZONE = "Europe/Berlin";

      PAPERLESS_APPS = "allauth.socialaccount.providers.openid_connect";
      PAPERLESS_SOCIAL_AUTO_SIGNUP = true;

      PAPERLESS_ENABLE_HTTP_REMOTE_USER = true;
      PAPERLESS_HTTP_REMOTE_USER_HEADER_NAME = "HTTP_REMOTE_USER";
      PAPERLESS_LOGOUT_REDIRECT_URL = "https://rproxy.osscar.me/logout";
      PAPERLESS_TRUSTED_PROXIES = "138.201.155.21,10.0.0.101";

      #PAPERLESS_DISABLE_REGULAR_LOGIN = true;
      # PAPERLESS_REDIRECT_LOGIN_TO_SSO = true;

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

    configureTika = false;
  };

  # open firewall for web interface
  networking.firewall.allowedTCPPorts = [
    28981
  ];

  # for shared bind-mounts (readonly access to documents)
  users = {
    groups = {
      paperless = {
        gid = lib.mkForce 10000; # maps to host 110000 (storage_shared)
      };
    };
    users.paperless = {
      isSystemUser = true;
      uid = lib.mkForce 1108; # container 108 -> uid 1108 -> host 101108
      group = "paperless";
    };
  };
}

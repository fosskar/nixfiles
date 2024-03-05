{
  config,
  pkgs,
  lib,
  ...
}: {
  services.healthchecks = {
    enable = true;
    port = 8003;
    package = pkgs.unstable.healthchecks;

    # Pass non-secret settings
    settings = {
      ALLOWED_HOSTS = ["healthchecks.space"];
      PING_ENDPOINT = "https://healthchecks.space/ping/";

      SITE_NAME = "Healthchecks";
      SITE_ROOT = "https://healthchecks.space";

      TZ = "UTC";
    };
  };
}

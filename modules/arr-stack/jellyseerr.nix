{
  config,
  lib,
  ...
}:
let
  cfg = config.nixfiles.arr-stack;
  acmeDomain = config.nixfiles.acme.domain;
  serviceDomain = "jellyseerr.${acmeDomain}";
  bindAddress = "127.0.0.1";
  port = 5055;
  internalUrl = "http://${bindAddress}:${toString port}";
in
{
  config = lib.mkIf cfg.jellyseerr.enable {
    # --- service ---

    services.jellyseerr = {
      enable = true;
      inherit port;
      openFirewall = false;
    };

    systemd.services.jellyseerr.serviceConfig.UMask = "0027";

    # --- homepage ---

    nixfiles.homepage.entries = lib.mkIf config.services.homepage-dashboard.enable [
      {
        name = "Jellyseerr";
        category = "Media";
        icon = "jellyseerr.svg";
        href = "https://${serviceDomain}";
        siteMonitor = internalUrl;
      }
    ];

    # --- gatus ---

    nixfiles.gatus.endpoints = lib.mkIf config.nixfiles.gatus.enable [
      {
        name = "Jellyseerr";
        url = "https://${serviceDomain}";
        group = "Media";
      }
    ];

    # --- nginx ---

    # no proxy-auth - jellyseerr has built-in auth
    nixfiles.nginx.vhosts.jellyseerr = {
      inherit port;
    };
  };
}

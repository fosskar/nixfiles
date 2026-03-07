{
  config,
  lib,
  ...
}:
let
  cfg = config.nixfiles.arr-stack;
  port = 5055;
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

    # --- nginx ---

    # no proxy-auth - jellyseerr has built-in auth
    nixfiles.nginx.vhosts.jellyseerr = {
      inherit port;
    };
  };
}

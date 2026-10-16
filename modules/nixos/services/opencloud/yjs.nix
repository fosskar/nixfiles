{
  flake.modules.nixos.opencloud =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      yjsPort = 1234;
      localHost = lib.removePrefix "https://" config.services.opencloud.url;
    in
    {
      config = {
        # yjs relay for collaborative editing (excalidraw, editor); holds no data
        # and checks every connection against the opencloud graph api itself
        systemd.services.opencloud-yjs = {
          description = "opencloud yjs collaboration server";
          after = [ "opencloud.service" ];
          wantedBy = [ "multi-user.target" ];
          environment = {
            NODE_ENV = "production";
            PORT = toString yjsPort;
            OPENCLOUD_URL = "http://${config.services.opencloud.address}:${toString config.services.opencloud.port}";
          };
          serviceConfig = {
            ExecStart = lib.getExe pkgs.local.opencloud-yjs;
            DynamicUser = true;
            Restart = "on-failure";
            NoNewPrivileges = true;
            CapabilityBoundingSet = "";
            ProtectSystem = "strict";
            ProtectHome = true;
            PrivateTmp = true;
            PrivateDevices = true;
          };
        };

        services.opencloud.environment.WEB_OPTION_YJS_SERVER_URL = "wss://${localHost}/yjs";

        # path matcher sorts this before the catch-all opencloud reverse_proxy;
        # hocuspocus authenticates inside the websocket, so no proxy auth here
        services.caddy.virtualHosts.${localHost}.extraConfig = ''
          reverse_proxy /yjs* 127.0.0.1:${toString yjsPort}
        '';
      };
    };
}

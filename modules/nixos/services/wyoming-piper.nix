{
  flake.modules.nixos.wyomingPiper =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      listenAddress = "127.0.0.1";
      listenPort = 10200;
      httpPort = 18082;
      localHost = "piper.${config.domains.local}";
      python = pkgs.python313.withPackages (ps: [
        ps.asgiref
        ps.flask
        ps.swagger-ui-py
        ps.wyoming
      ]);
    in
    {
      services.wyoming.piper.servers.default = {
        enable = true;
        voice = "en_US-ryan-high";
        uri = "tcp://${listenAddress}:${toString listenPort}";
        useCUDA = true;
        zeroconf.enable = false;
      };

      systemd.services.wyoming-piper-http = {
        description = "HTTP wrapper for Wyoming Piper";
        after = [ "wyoming-piper-default.service" ];
        requires = [ "wyoming-piper-default.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          ExecStart = "${python}/bin/python -m wyoming.http.tts_server --host ${listenAddress} --port ${toString httpPort} --uri tcp://127.0.0.1:${toString listenPort}";
          Restart = "always";
          RestartSec = 5;
        };
      };

      systemd.services.wyoming-piper-default.serviceConfig = {
        DevicePolicy = lib.mkForce "auto";
        PrivateDevices = lib.mkForce false;
      };

      services.caddy.virtualHosts.${localHost}.extraConfig = ''
        reverse_proxy http://${listenAddress}:${toString httpPort}
      '';

      services.gatus.settings.endpoints = lib.mkIf config.services.gatus.enable [
        {
          name = "Wyoming Piper";
          url = "http://${listenAddress}:${toString httpPort}/api/info";
          group = "AI";
          enabled = true;
          interval = "5m";
          conditions = [ "[STATUS] == 200" ];
          alerts = [ { type = "email"; } ];
        }
      ];
    };
}

{
  flake.modules.nixos.wyomingPiper =
    {
      nflib,
      config,
      lib,
      pkgs,
      ...
    }:
    let
      wyomingAddress = "0.0.0.0";
      httpAddress = "127.0.0.1";
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
        uri = "tcp://${wyomingAddress}:${toString listenPort}";
        useCUDA = true;
        zeroconf.enable = false;
      };

      systemd.services.wyoming-piper-http = {
        description = "HTTP wrapper for Wyoming Piper";
        after = [ "wyoming-piper-default.service" ];
        requires = [ "wyoming-piper-default.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          ExecStart = "${python}/bin/python -m wyoming.http.tts_server --host ${httpAddress} --port ${toString httpPort} --uri tcp://127.0.0.1:${toString listenPort}";
          Restart = "always";
          RestartSec = 5;
        };
      };

      networking.firewall.allowedTCPPorts = [ listenPort ];

      systemd.services.wyoming-piper-default.serviceConfig = {
        DevicePolicy = lib.mkForce "auto";
        PrivateDevices = lib.mkForce false;
      };

      services.caddy.virtualHosts.${localHost}.extraConfig = ''
        reverse_proxy http://${httpAddress}:${toString httpPort}
      '';

      services.gatus.settings.endpoints = lib.mkIf config.services.gatus.enable [
        (nflib.gatusEndpoint {
          name = "Wyoming Piper";
          url = "http://${httpAddress}:${toString httpPort}/api/info";
          group = "AI";
        })
      ];
    };
}

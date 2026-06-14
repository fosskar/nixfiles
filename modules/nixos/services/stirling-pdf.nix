{
  flake.modules.nixos.stirlingPdf =
    {
      nflib,
      flake-self,
      config,
      lib,
      ...
    }:
    let
      serviceName = "pdf";
      localHost = "${serviceName}.${flake-self.domains.local}";
      listenAddress = "127.0.0.1";
      listenPort = 8180;
      listenUrl = "http://${listenAddress}:${toString listenPort}";
    in
    {
      services.stirling-pdf = {
        enable = true;
        environment = {
          SERVER_PORT = toString listenPort;
          SYSTEM_ENABLEANALYTICS = "false";
          SECURITY_ENABLELOGIN = "false";
          JAVA_TOOL_OPTIONS = "-Xmx512m";
          STIRLING_LOCK_CONNECTION = "1";
        };
      };

      services.homepage-dashboard.serviceGroups."Tools" =
        lib.mkIf config.services.homepage-dashboard.enable
          [
            {
              "Stirling PDF" = {
                href = "https://${localHost}";
                icon = "stirling-pdf.svg";
                siteMonitor = listenUrl;
              };
            }
          ];

      services.gatus.settings.endpoints = lib.mkIf config.services.gatus.enable [
        (nflib.gatusEndpoint {
          name = "Stirling PDF";
          url = "https://${localHost}";
          group = "Tools";
        })
      ];

      services.caddy.virtualHosts.${localHost}.extraConfig = ''
        reverse_proxy ${listenUrl}
      '';
    };
}

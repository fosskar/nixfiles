{
  flake.modules.nixos.stirlingPdf =
    {
      config,
      domains,
      lib,
      pkgs,
      ...
    }:
    let
      serviceName = "pdf";
      localHost = "${serviceName}.${domains.local}";
      listenAddress = "127.0.0.1";
      listenPort = 8180;
      listenUrl = "http://${listenAddress}:${toString listenPort}";
    in
    {
      services.stirling-pdf = {
        enable = true;
        package = pkgs.custom.stirling-pdf;
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
        {
          name = "Stirling PDF";
          url = "https://${localHost}";
          group = "Tools";
          enabled = true;
          interval = "5m";
          conditions = [ "[STATUS] == 200" ];
          alerts = [ { type = "ntfy"; } ];
        }
      ];

      services.caddy.virtualHosts.${localHost}.extraConfig = ''
        reverse_proxy ${listenUrl}
      '';
    };
}

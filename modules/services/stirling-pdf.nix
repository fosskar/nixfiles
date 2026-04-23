{
  flake.modules.nixos.stirlingPdf =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      acmeDomain = "nx3.eu";
      serviceDomain = "pdf.${acmeDomain}";
      bindAddress = "127.0.0.1";
      port = 8180;
      internalUrl = "http://${bindAddress}:${toString port}";
    in
    {
      services.stirling-pdf = {
        enable = true;
        package = pkgs.custom.stirling-pdf;
        environment = {
          SERVER_PORT = toString port;
          SYSTEM_ENABLEANALYTICS = "false";
          SECURITY_ENABLELOGIN = "false";
          JAVA_TOOL_OPTIONS = "-Xmx512m";
          STIRLING_LOCK_CONNECTION = "1";
        };
      };

      services.homepage-dashboard.services = lib.mkIf config.services.homepage-dashboard.enable [
        {
          "Tools" = [
            {
              "Stirling PDF" = {
                href = "https://${serviceDomain}";
                icon = "stirling-pdf.svg";
                siteMonitor = internalUrl;
              };
            }
          ];
        }
      ];

      services.gatus.settings.endpoints = lib.mkIf config.services.gatus.enable [
        {
          name = "Stirling PDF";
          url = "https://${serviceDomain}";
          group = "Tools";
          enabled = true;
          interval = "5m";
          conditions = [ "[STATUS] == 200" ];
          alerts = [ { type = "ntfy"; } ];
        }
      ];

      services.caddy.virtualHosts."pdf.nx3.eu".extraConfig = ''
        reverse_proxy 127.0.0.1:${toString port}
      '';
    };
}

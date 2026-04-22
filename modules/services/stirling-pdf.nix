{
  flake.modules.nixos.stirlingPdf =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      acmeDomain = config.nixfiles.caddy.domain;
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

      nixfiles.homepage.entries = lib.mkIf config.services.homepage-dashboard.enable [
        {
          name = "Stirling PDF";
          category = "Tools";
          icon = "stirling-pdf.svg";
          href = "https://${serviceDomain}";
          siteMonitor = internalUrl;
        }
      ];

      nixfiles.gatus.endpoints = lib.mkIf config.services.gatus.enable [
        {
          name = "Stirling PDF";
          url = "https://${serviceDomain}";
          group = "Tools";
        }
      ];

      nixfiles.caddy.vhosts.pdf = {
        inherit port;
      };
    };
}

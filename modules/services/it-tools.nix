{
  flake.modules.nixos.itTools =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      acmeDomain = config.nixfiles.caddy.domain;
      serviceDomain = "tools.${acmeDomain}";
    in
    {
      # --- homepage ---
      nixfiles.homepage.entries = lib.mkIf config.services.homepage-dashboard.enable [
        {
          name = "IT Tools";
          category = "Tools";
          icon = "it-tools.svg";
          href = "https://${serviceDomain}";
          siteMonitor = "https://${serviceDomain}";
        }
      ];

      # --- gatus ---
      nixfiles.gatus.endpoints = lib.mkIf config.services.gatus.enable [
        {
          name = "IT Tools";
          url = "https://${serviceDomain}";
          group = "Tools";
        }
      ];

      # --- caddy ---
      nixfiles.caddy.vhosts.tools = {
        root = "${pkgs.it-tools}/lib";
      };
    };
}

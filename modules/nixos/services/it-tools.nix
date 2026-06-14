{
  flake.modules.nixos.itTools =
    {
      nflib,
      flake-self,
      config,
      lib,
      pkgs,
      ...
    }:
    let
      serviceName = "tools";
      localHost = "${serviceName}.${flake-self.domains.local}";
    in
    {
      # --- homepage ---
      services.homepage-dashboard.serviceGroups."Tools" =
        lib.mkIf config.services.homepage-dashboard.enable
          [
            {
              "IT Tools" = {
                href = "https://${localHost}";
                icon = "it-tools.svg";
                siteMonitor = "https://${localHost}";
              };
            }
          ];

      # --- gatus ---
      services.gatus.settings.endpoints = lib.mkIf config.services.gatus.enable [
        (nflib.gatusEndpoint {
          name = "IT Tools";
          url = "https://${localHost}";
          group = "Tools";
        })
      ];

      # --- caddy ---
      services.caddy.virtualHosts.${localHost}.extraConfig = ''
        root * ${pkgs.it-tools}/lib
        file_server
        try_files {path} {path}.html {path}/ =404
      '';
    };
}

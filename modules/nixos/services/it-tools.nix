{
  flake.modules.nixos.itTools =
    {
      nflib,
      flake-self,
      pkgs,
      ...
    }:
    let
      serviceName = "tools";
      localHost = "${serviceName}.${flake-self.domains.local}";
    in
    {
      # --- homepage ---
      services.homepage-dashboard.serviceGroups."tools" = [
        {
          "IT Tools" = {
            href = "https://${localHost}";
            icon = "it-tools.svg";
            siteMonitor = "https://${localHost}";
          };
        }
      ];

      # --- gatus ---
      services.gatus.settings.endpoints = [
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

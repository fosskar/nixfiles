{
  flake.modules.nixos.photocraft =
    {
      flake-self,
      pkgs,
      ...
    }:
    let
      serviceName = "photocraft";
      localHost = "${serviceName}.${flake-self.domains.local}";
    in
    {
      services.homepage-dashboard.services = [
        {
          "tools" = [
            {
              "PhotoCraft" = {
                href = "https://${localHost}";
                icon = "mdi-image-edit";
                siteMonitor = "https://${localHost}";
              };
            }
          ];
        }
      ];

      services.gatus.settings.endpoints = [
        {
          name = "PhotoCraft";
          url = "https://${localHost}";
          enabled = true;
          alerts = [ { type = "matrix"; } ];
          interval = "5m";
          conditions = [ "[STATUS] == 200" ];
        }
      ];

      services.caddy.virtualHosts.${localHost}.extraConfig = ''
        root * ${pkgs.local.photocraft-web}
        encode zstd gzip
        @hashed path *.wasm *.js
        header @hashed Cache-Control "public, max-age=31536000, immutable"
        header /index.html Cache-Control "no-cache"
        file_server
      '';
    };
}

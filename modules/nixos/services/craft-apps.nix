let
  # artcraft crafting apps share one static wasm site layout; the attr name is the repo and module name
  apps = {
    photocraft = "PhotoCraft";
    vectorcraft = "VectorCraft";
    pdfcraft = "PdfCraft";
  };

  mkCraftApp =
    serviceName: displayName:
    {
      flake-self,
      pkgs,
      ...
    }:
    let
      localHost = "${serviceName}.${flake-self.domains.local}";
      site = pkgs.local."${serviceName}-web";
    in
    {
      services.homepage-dashboard.services = [
        {
          "tools" = [
            {
              ${displayName} = {
                href = "https://${localHost}";
                icon = "https://raw.githubusercontent.com/storytold/${serviceName}/${site.src.tag}/assets/app-icon/hicolor/128x128/apps/ai.storyteller.${serviceName}.png";
                siteMonitor = "https://${localHost}";
              };
            }
          ];
        }
      ];

      services.gatus.settings.endpoints = [
        {
          name = displayName;
          url = "https://${localHost}";
          enabled = true;
          alerts = [ { type = "matrix"; } ];
          interval = "5m";
          conditions = [ "[STATUS] == 200" ];
        }
      ];

      services.caddy.virtualHosts.${localHost}.extraConfig = ''
        root * ${site}
        encode zstd gzip
        @hashed path *.wasm *.js
        header @hashed Cache-Control "public, max-age=31536000, immutable"
        header /index.html Cache-Control "no-cache"
        file_server
      '';
    };
in
{
  flake.modules.nixos = builtins.mapAttrs mkCraftApp apps;
}

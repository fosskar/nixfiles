{
  flake.modules.nixos.laya =
    {
      config,
      flake-self,
      pkgs,
      ...
    }:
    let
      localHost = "laya.${flake-self.domains.local}";
      llamaCpp = config.services.llama-cpp.settings;
      listenUrl = "http://${llamaCpp.host}:${toString llamaCpp.port}";
      themeCss = pkgs.writeText "theme.css" (
        import ./_theme-css.nix flake-self.themes.${flake-self.theme}
      );
      webRoot = pkgs.runCommand "laya-web" { } ''
        mkdir $out
        cp ${./web/index.html} $out/index.html
        cp ${themeCss} $out/theme.css
      '';
    in
    {
      services.homepage-dashboard.services = [
        {
          "tools" = [
            {
              "Laya" = {
                href = "https://${localHost}";
                icon = "mdi-scale-balance";
                siteMonitor = "${listenUrl}/health";
              };
            }
          ];
        }
      ];

      services.gatus.settings.endpoints = [
        {
          name = "laya";
          url = "https://${localHost}/health";
          enabled = true;
          alerts = [ { type = "matrix"; } ];
          interval = "5m";
          conditions = [ "[STATUS] == 200" ];
        }
      ];

      # laya is served by the llama-cpp router; pass only the decision api
      # through and serve a plain form instead of the llama.cpp web ui
      services.caddy.virtualHosts.${localHost}.extraConfig = ''
        handle /v1/systemone {
          reverse_proxy ${listenUrl}
        }
        handle /health {
          reverse_proxy ${listenUrl}
        }
        handle {
          root * ${webRoot}
          file_server
        }
      '';
    };
}

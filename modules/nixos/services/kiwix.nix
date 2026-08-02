{
  flake.modules.nixos.kiwix =
    {
      flake-self,
      pkgs,
      ...
    }:
    let
      localHost = "kiwix.${flake-self.domains.local}";
      listenPort = 18090;
      listenUrl = "http://127.0.0.1:${toString listenPort}";
    in
    {
      services.kiwix-serve = {
        enable = true;
        address = "127.0.0.1";
        port = listenPort;
        library.archwiki = pkgs.fetchurl {
          urls = [
            "https://mirror.download.kiwix.org/zim/other/archlinux_en_all_maxi_2026-07.zim"
            "https://ftp.fau.de/kiwix/zim/other/archlinux_en_all_maxi_2026-07.zim"
          ];
          hash = "sha256-w99VEBCpU9LBc6+NZaWWp85DSn+gdxdBvIAP7sytGUI=";
        };
      };

      services.homepage-dashboard.services = [
        {
          "llm" = [
            {
              "Kiwix" = {
                href = "https://${localHost}";
                icon = "sh-kiwix";
                siteMonitor = listenUrl;
              };
            }
          ];
        }
      ];

      services.gatus.settings.endpoints = [
        {
          name = "kiwix";
          url = "https://${localHost}/";
          enabled = true;
          alerts = [ { type = "email"; } ];
          interval = "5m";
          conditions = [ "[STATUS] == 200" ];
        }
      ];

      services.caddy.virtualHosts.${localHost}.extraConfig = ''
        reverse_proxy ${listenUrl}
      '';
    };
}

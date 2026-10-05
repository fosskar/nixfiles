{
  flake.modules.nixos.arrStack =
    {
      flake-self,
      config,
      lib,
      pkgs,
      ...
    }:
    let
      mediaRoot = "/tank/media";
      serviceName = "chaptarr";
      localHost = "${serviceName}.${flake-self.domains.local}";
      listenAddress = "127.0.0.1";
      listenPort = 8789;
      listenUrl = "http://${listenAddress}:${toString listenPort}";
    in
    {
      imports = [ flake-self.modules.nixos.chaptarr ];

      config = {
        # --- service ---

        services.chaptarr = {
          enable = true;
          openFirewall = false;
          group = "media";
          extraPackages = [ pkgs.ffmpeg ];
          # the unit runs with ProtectSystem=strict
          extraReadWritePaths = [
            "${mediaRoot}/books"
            "${mediaRoot}/downloads"
          ];
          settings = {
            auth = lib.mkIf (config.services.authelia.instances.main.enable or false) {
              method = "External";
              required = "Enabled";
            };
            server = {
              bindaddress = listenAddress;
              port = listenPort;
            };
          };
        };

        # preserve group-write on created files/dirs so other media-group
        # services can write into per-book subdirs.
        systemd.services.chaptarr.serviceConfig.UMask = lib.mkForce "0002";

        # --- homepage ---

        services.homepage-dashboard.services = [
          {
            "arr-stack" = [
              {
                "Chaptarr" = {
                  href = "https://${localHost}";
                  icon = "chaptarr.svg";
                  siteMonitor = listenUrl;
                };
              }
            ];
          }
        ];

        # --- gatus ---

        services.gatus.settings.endpoints = [
          {
            name = "Chaptarr";
            # backend check on purpose: the edge is forward-auth, authelia answers 302 without reaching the service
            url = listenUrl;
            enabled = true;
            alerts = [ { type = "matrix"; } ];
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }
        ];

        # --- caddy ---

        services.caddy.virtualHosts.${localHost}.extraConfig = ''
          ${lib.optionalString (config.services.authelia.instances.main.enable or false) "import authelia"}
          reverse_proxy ${listenUrl}
        '';

        # --- backup ---

        clan.core.state.chaptarr = {
          folders = [ "/var/backup/chaptarr" ];
          preBackupScript = ''
            export PATH=${
              lib.makeBinPath [
                pkgs.sqlite
                pkgs.coreutils
              ]
            }
            mkdir -p /var/backup/chaptarr
            sqlite3 /var/lib/chaptarr/chaptarr.db ".backup '/var/backup/chaptarr/chaptarr.db'"
          '';
        };
      };
    };
}

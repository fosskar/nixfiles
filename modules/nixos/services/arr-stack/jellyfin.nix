{
  flake.modules.nixos.arrStack =
    {
      nflib,
      flake-self,
      lib,
      pkgs,
      ...
    }:
    let
      serviceName = "jellyfin";
      localHost = "${serviceName}.${flake-self.domains.local}";
      listenAddress = "127.0.0.1";
      listenPort = 8096;
      listenUrl = "http://${listenAddress}:${toString listenPort}";
    in
    {
      config = {
        # --- service ---

        services.jellyfin = {
          enable = true;
          openFirewall = false;
          group = "media";
          forceEncodingConfig = true;
          hardwareAcceleration = {
            enable = true;
            device = "/dev/nvidia0";
            type = "nvenc";
          };
          transcoding = {
            deleteSegments = true;
            enableHardwareEncoding = true;
            hardwareDecodingCodecs = {
              h264 = true;
              hevc = true;
              vc1 = true;
              vp9 = true;
              av1 = true;
              hevc10bit = true;
            };
          };
        };

        users.users.jellyfin.extraGroups = [
          "render"
          "video"
        ];

        environment.systemPackages = [
          pkgs.jellyfin
          pkgs.jellyfin-web
          pkgs.jellyfin-ffmpeg
        ];

        systemd.tmpfiles.rules = [
          "d /dev/shm/jellyfin-transcodes 0750 jellyfin media -"
        ];

        # --- homepage ---

        services.homepage-dashboard.serviceGroups."media" = [
          {
            "Jellyfin" = {
              href = "https://${localHost}";
              icon = "jellyfin.png";
              siteMonitor = listenUrl;
            };
          }
        ];

        # --- gatus ---

        services.gatus.settings.endpoints = [
          (nflib.gatusEndpoint {
            name = "Jellyfin";
            url = listenUrl;
            group = "Media";
          })
        ];

        # --- caddy ---

        # no proxy-auth - jellyfin has built-in auth
        services.caddy.virtualHosts.${localHost}.extraConfig = ''
          reverse_proxy ${listenUrl} {
            flush_interval -1
          }
        '';

        # --- backup ---

        clan.core.state.jellyfin = {
          folders = [ "/var/backup/jellyfin" ];
          preBackupScript = ''
            export PATH=${
              lib.makeBinPath [
                pkgs.sqlite
                pkgs.coreutils
              ]
            }
            mkdir -p /var/backup/jellyfin
            sqlite3 /var/lib/jellyfin/data/jellyfin.db ".backup '/var/backup/jellyfin/jellyfin.db'"
          '';
        };

        # --- systemd ---

        systemd.services.jellyfin.serviceConfig.DeviceAllow = [
          "/dev/nvidiactl rw"
          "/dev/nvidia-modeset rw"
          "/dev/nvidia-uvm rw"
          "/dev/nvidia-uvm-tools rw"
        ];
      };
    };
}

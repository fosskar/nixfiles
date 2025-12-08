{ ... }:
{
  services.glances.enable = true;
  services.homepage-dashboard = {
    enable = true;
    listenPort = 8082;
    openFirewall = false;

    # allow access from network (not just localhost)
    allowedHosts = "home.osscar.me";

    # environment file for secrets (proxmox api tokens, etc.)
    #environmentFile = config.sops.secrets."homepage.env".path;

    # basic settings
    settings = {
      title = "home-lab dashboard";
      headerStyle = "clean"; # "boxedWidgets"
      useEqualheights = true;
      hideVersion = true;
      disableUpdateCheck = true;
      description = "a description of my  homepage";
      cardBlur = "xl"; # xs, sm, md, lg, xl, 2xl, 3xl - see https://tailwindcss.com/docs/backdrop-blur

      # show dots instead of response times for ping/siteMonitor
      statusStyle = "dot";

      layout = [
        {
          Glances = {
            header = false;
            style = "row";
          };
        }
        {
          Network = {
            header = true;
          };
        }
        {
          Infrastructure = {
            header = true;
            style = "row";
            columns = 3;
          };
        }
        {
          Monitoring = {
            header = true;
          };
        }
        {
          Media = {
            header = true;
          };
        }
        {
          Documents = {
            header = true;
          };
        }
        {
          "AI / LLM" = {
            header = true;
          };
        }
        {
          Security = {
            header = true;
          };
        }
        {
          Automation = {
            header = true;
          };
        }
        {
          "Arr Stack" = {
            header = true;
            style = "row";
            columns = 3;
            initiallyCollapsed = true;
          };
        }
      ];

      #  title = "home dashboard";
      #  favicon = "https://gethomepage.dev/img/favicon.ico";
      #  headerStyle = "boxed";
    };

    # https://gethomepage.dev/latest/configs/custom-css-js/
    customJS = "";
    customCSS = "";

    # services to display on dashboard
    services = [
      {
        "Network" = [
          {
            "OpenWrt Router" = {
              href = "https://192.168.10.1";
              icon = "openwrt.svg";
              siteMonitor = "https://192.168.10.1";
            };
          }
          {
            "OpenWrt AP" = {
              href = "https://192.168.10.2";
              icon = "openwrt.svg";
              siteMonitor = "https://192.168.10.2";
            };
          }
          {
            "Pangolin local" = {
              href = "https://pango.osscar.me";
              icon = "pangolin.png";
            };
          }
          {
            "Pangolin public" = {
              href = "https://pangolin.simonoscar.me";
              icon = "pangolin.png";
            };
          }
        ];
      }
      {
        "Infrastructure" = [
          {
            "JetKVM HA" = {
              href = "http://jetkvm-ha.lan";
              icon = "mdi-console";
              siteMonitor = "http://192.168.10.30";
            };
          }
        ];
      }
      {
        "Media" = [
          {
            "Immich" = {
              href = "https://immich.osscar.me";
              icon = "immich.png";
              siteMonitor = "http://127.0.0.1:2283";
            };
          }
          {
            "Jellyfin" = {
              href = "https://jellyfin.osscar.me";
              icon = "jellyfin.png";
              siteMonitor = "http://127.0.0.1:8096";
            };
          }
          {
            "Audiobookshelf" = {
              href = "https://audiobookshelf.osscar.me";
              icon = "audiobookshelf.svg";
              siteMonitor = "http://127.0.0.1:13378";
            };
          }
        ];
      }
      {
        "Arr Stack" = [
          {
            "Prowlarr" = {
              href = "https://prowlarr.osscar.me";
              icon = "prowlarr.svg";
              siteMonitor = "http://127.0.0.1:9696";
            };
          }
          {
            "Sonarr" = {
              href = "https://sonarr.osscar.me";
              icon = "sonarr.svg";
              siteMonitor = "http://127.0.0.1:8989";
            };
          }
          {
            "Radarr" = {
              href = "https://radarr.osscar.me";
              icon = "radarr.svg";
              siteMonitor = "http://127.0.0.1:7878";
            };
          }
          {
            "Lidarr" = {
              href = "https://lidarr.osscar.me";
              icon = "lidarr.svg";
              siteMonitor = "http://127.0.0.1:8686";
            };
          }
          {
            "Readarr" = {
              href = "https://readarr.osscar.me";
              icon = "readarr.svg";
              siteMonitor = "http://127.0.0.1:8787";
            };
          }
          {
            "Jellyseerr" = {
              href = "https://jellyseerr.osscar.me";
              icon = "jellyseerr.svg";
              siteMonitor = "http://127.0.0.1:5055";
            };
          }
          {
            "SABnzbd" = {
              href = "https://sabnzbd.osscar.me";
              icon = "sabnzbd.svg";
              siteMonitor = "http://127.0.0.1:8080";
            };
          }
        ];
      }
      {
        "AI / LLM" = [
          {
            "Ollama" = {
              description = "local llm inference engine";
              href = "http://127.0.0.1:11434";
              icon = "ollama.png";
              siteMonitor = "http://127.0.0.1:11434";
            };
          }
        ];
      }
      {
        "Documents" = [
          {
            "Paperless" = {
              href = "https://docs.osscar.me";
              icon = "paperless.png";
              siteMonitor = "http://127.0.0.1:28981";
            };
          }
          {
            "Nextcloud" = {
              href = "https://cloud.osscar.me";
              icon = "nextcloud.svg";
              siteMonitor = "http://127.0.0.1:8009/status.php";
            };
          }
        ];
      }
      {
        "Monitoring" = [
          {
            "VictoriaMetrics" = {
              href = "https://vm.osscar.me";
              icon = "victoriametrics.svg";
              siteMonitor = "https://vm.osscar.me";
            };
          }
          {
            "Grafana" = {
              href = "https://grafana.osscar.me";
              icon = "grafana.svg";
              siteMonitor = "https://grafana.osscar.me";
            };
          }
        ];
      }
      {
        Security = [
          {
            "AdGuard Home" = {
              href = "http://192.168.10.1:8080";
              icon = "adguard-home.svg";
              siteMonitor = "http://192.168.10.1:8080";
            };
          }
          {
            "Vaultwarden" = {
              href = "https://vault.osscar.me";
              icon = "vaultwarden.svg";
              siteMonitor = "http://127.0.0.1:8222";
            };
          }
        ];
      }
      {
        "Automation" = [
          {
            "Home Assistant" = {
              href = "https://ha.simonoscar.me";
              icon = "home-assistant.svg";
              siteMonitor = "http://192.168.10.30";
            };
          }
        ];
      }
      #{
      #  "Files" = [
      #    {
      #      "samba" = {
      #        description = "network file sharing";
      #        href = "smb://192.168.10.104";
      #        icon = "samba.svg";
      #      };
      #    }
      #  ];
      #}
    ];
    # https://gethomepage.dev/latest/configs/service-widgets/
    widgets = [
    ];
  };
}

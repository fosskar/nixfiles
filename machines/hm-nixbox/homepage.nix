{ config, ... }:
{
  services.glances.enable = true;
  services.homepage-dashboard = {
    enable = true;
    listenPort = 8082;
    openFirewall = false;

    # allow access from network (not just localhost)
    allowedHosts = "home.osscar.me";

    # environment file for secrets (proxmox api tokens, etc.)
    environmentFile = config.sops.secrets."homepage.env".path;

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
              href = "https://rproxy.osscar.me";
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
              href = "https://photos.osscar.me";
              icon = "immich.png";
              siteMonitor = "http://10.0.0.107:2283";
              widget = {
                type = "immich";
                url = "http://10.0.0.107:2283";
                key = "{{HOMEPAGE_VAR_IMMICH_KEY}}";
                version = 2;
                fields = [
                  "photos"
                  "videos"
                ];
              };
            };
          }
          {
            "Jellyfin" = {
              href = "https://jellyfin.osscar.me";
              icon = "jellyfin.png";
              siteMonitor = "http://10.0.0.111:8096";
              widget = {
                type = "jellyfin";
                url = "http://10.0.0.111:8096";
                key = "{{HOMEPAGE_VAR_JELLYFIN_KEY}}";
                enableBlocks = true;
                fields = [
                  "movies"
                  "episodes"
                ];
                enableNowPlaying = true;
                enableUser = true;
                showEpisodeNumber = true;
                expandOneStreamToTwoRows = false;
              };
            };
          }
          {
            "Audiobookshelf" = {
              href = "https://audiobookshelf.osscar.me";
              icon = "audiobookshelf.svg";
              siteMonitor = "http://10.0.0.111:13378";
              widget = {
                type = "audiobookshelf";
                url = "http://10.0.0.111:13378";
                key = "{{HOMEPAGE_VAR_AUDIOBOOKSHELF_KEY}}";
              };
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
              siteMonitor = "http://10.0.0.110:9696";
              widget = {
                type = "prowlarr";
                url = "http://10.0.0.110:9696";
                key = "{{HOMEPAGE_VAR_PROWLARR_KEY}}";
              };
            };
          }
          {
            "Sonarr" = {
              href = "https://sonarr.osscar.me";
              icon = "sonarr.svg";
              siteMonitor = "http://10.0.0.110:8989";
              widget = {
                type = "sonarr";
                url = "http://10.0.0.110:8989";
                key = "{{HOMEPAGE_VAR_SONARR_KEY}}";
              };
            };
          }
          {
            "Radarr" = {
              href = "https://radarr.osscar.me";
              icon = "radarr.svg";
              siteMonitor = "http://10.0.0.110:7878";
              widget = {
                type = "radarr";
                url = "http://10.0.0.110:7878";
                key = "{{HOMEPAGE_VAR_RADARR_KEY}}";
              };
            };
          }
          {
            "Lidarr" = {
              href = "https://lidarr.osscar.me";
              icon = "lidarr.svg";
              siteMonitor = "http://10.0.0.110:8686";
              widget = {
                type = "lidarr";
                url = "http://10.0.0.110:8686";
                key = "{{HOMEPAGE_VAR_LIDARR_KEY}}";
              };
            };
          }
          {
            "Readarr" = {
              href = "https://readarr.osscar.me";
              icon = "readarr.svg";
              siteMonitor = "http://10.0.0.110:8787";
              widget = {
                type = "readarr";
                url = "http://10.0.0.110:8787";
                key = "{{HOMEPAGE_VAR_READARR_KEY}}";
              };
            };
          }
          {
            "Jellyseerr" = {
              href = "https://jellyseerr.osscar.me";
              icon = "jellyseerr.svg";
              siteMonitor = "http://10.0.0.110:5055";
              widget = {
                type = "jellyseerr";
                url = "http://10.0.0.110:5055";
                key = "{{HOMEPAGE_VAR_JELLYSEERR_KEY}}";
                fields = [
                  "pending"
                  "approved"
                  "available"
                ];
              };
            };
          }
          {
            "sabnzbd" = {
              href = "https://usenet.osscar.me";
              icon = "sabnzbd.svg";
              siteMonitor = "http://10.0.0.110:8080";
              widget = {
                type = "sabnzbd";
                url = "http://10.0.0.110:8080";
                key = "{{HOMEPAGE_VAR_SABNZBD_KEY}}";
              };
            };
          }
        ];
      }
      {
        "AI / LLM" = [
          {
            "Open WebUI" = {
              href = "https://llm.osscar.me";
              icon = "openwebui.svg";
              siteMonitor = "http://10.0.0.106:11111";
            };
          }
          {
            "Ollama" = {
              description = "local llm inference engine";
              href = "http://10.0.0.106:11434";
              icon = "ollama.png";
              siteMonitor = "http://10.0.0.106:11434";
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
              siteMonitor = "http://10.0.0.108:28981";
              widget = {
                type = "paperlessngx";
                url = "http://10.0.0.108:28981";
                key = "{{HOMEPAGE_VAR_PAPERLESS_KEY}}";
              };
            };
          }
          {
            "Paperless-GPT" = {
              href = "https://docs-gpt.osscar.me";
              icon = "paperless.png";
              siteMonitor = "http://10.0.0.108:8080";
            };
          }
          {
            "Paperless-AI" = {
              href = "https://docs-ai.osscar.me";
              icon = "paperless.png";
              siteMonitor = "http://10.0.0.108:5005";
            };
          }
          {
            "Nextcloud" = {
              href = "https://cloud.osscar.me";
              icon = "nextcloud.svg";
              siteMonitor = "http://10.0.0.112:8009";
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
              siteMonitor = "http://10.0.0.102:8428";
            };
          }
          {
            "Grafana" = {
              href = "https://grafana.osscar.me";
              icon = "grafana.svg";
              siteMonitor = "http://10.0.0.102:3000";
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
            "Pocket-ID" = {
              href = "https://auth.simonoscar.me";
              icon = "mdi-shield-account";
              siteMonitor = "http://10.0.0.105:1411";
            };
          }
          {
            "Vaultwarden" = {
              href = "https://vault.osscar.me";
              icon = "vaultwarden.svg";
              siteMonitor = "http://10.0.0.109:8222";
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

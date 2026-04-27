{
  flake.modules.nixos.homepage = _: {
    services.homepage-dashboard = {
      # layout ordering and column config
      settings.layout = [
        {
          Network = {
            header = true;
            columns = 2;
          };
        }
        {
          Monitoring = {
            header = true;
            style = "column";
          };
        }
        {
          Infrastructure = {
            header = true;
          };
        }
        {
          Automation = {
            header = true;
          };
        }
        {
          Media = {
            header = true;
          };
        }
        {
          Files = {
            header = true;
          };
        }
        {
          Tools = {
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
          "Arr Stack" = {
            header = true;
            columns = 2;
            initiallyCollapsed = true;
          };
        }
      ];

      # services on other machines — can't auto-register cross-machine
      serviceGroups = {
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
            "AdGuard Home" = {
              href = "http://192.168.10.1:8080";
              icon = "adguard-home.svg";
              siteMonitor = "http://192.168.10.1:8080";
            };
          }
          {
            "NetBird" = {
              href = "https://nb.fosskar.eu";
              icon = "netbird.svg";
              siteMonitor = "https://nb.fosskar.eu";
            };
          }
        ];
        "Infrastructure" = [
          {
            "JetKVM HA" = {
              href = "http://jetkvm-ha.lan";
              icon = "mdi-console";
              siteMonitor = "http://192.168.10.30";
            };
          }
          {
            "ASRock Rack BMC" = {
              href = "https://192.168.10.114";
              icon = "mdi-server-network";
              siteMonitor = "https://192.168.10.114";
            };
          }
          {
            "HP Drucker" = {
              href = "http://192.168.10.153";
              icon = "mdi-printer";
              siteMonitor = "http://192.168.10.153";
            };
          }
        ];
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
        "Tools" = [
          {
            "fosskar's bliki" = {
              href = "https://fosskar.nx3.eu/";
              icon = "mdi-book-open-variant";
              siteMonitor = "https://fosskar.nx3.eu/";
            };
          }
        ];
        "Automation" = [
          {
            "Buildbot" = {
              href = "https://buildbot.fosskar.eu/";
              icon = "buildbot.svg";
              siteMonitor = "https://buildbot.fosskar.eu/";
            };
          }
          {
            "Radicle" = {
              href = "https://radicle.fosskar.eu/";
              icon = "mdi-source-branch";
              siteMonitor = "https://radicle.fosskar.eu/";
            };
          }
          {
            "Home Assistant" = {
              href = "https://ha.fosskar.eu";
              icon = "home-assistant.svg";
              siteMonitor = "http://192.168.10.30";
            };
          }
          {
            "Syncthing" = {
              href = "http://127.0.0.1:8384";
              icon = "syncthing.svg";
            };
          }
        ];
      };

      bookmarks = [
        {
          "NixOS" = [
            {
              "NixOS Search" = [
                {
                  icon = "nixos.svg";
                  href = "https://search.nixos.org";
                }
              ];
            }
            {
              "Nixpkgs Repo" = [
                {
                  icon = "github.svg";
                  href = "https://github.com/NixOS/nixpkgs";
                }
              ];
            }
          ];
        }
        {
          "Home Manager" = [
            {
              "Home Manager Search" = [
                {
                  icon = "nixos.svg";
                  href = "https://home-manager-options.extranix.com";
                }
              ];
            }
            {
              "Home Manager Repo" = [
                {
                  icon = "github.svg";
                  href = "https://github.com/nix-community/home-manager";
                }
              ];
            }
          ];
        }
        {
          "DNS Management" = [
            {
              "deSEC" = [
                {
                  icon = "mdi-dns";
                  href = "https://desec.io/domains";
                }
              ];
            }
            {
              "inwx" = [
                {
                  icon = "mdi-domain";
                  href = "https://www.inwx.de/en/";
                }
              ];
            }
          ];
        }
        {
          "Clan" = [
            {
              "Clan Docs" = [
                {
                  icon = "mdi-book-open-variant";
                  href = "https://docs.clan.lol/";
                }
              ];
            }
            {
              "Clan Search" = [
                {
                  icon = "mdi-magnify";
                  href = "https://docs.clan.lol/option-search/";
                }
              ];
            }
            {
              "Clan Repo" = [
                {
                  icon = "gitea.svg";
                  href = "https://git.clan.lol/clan/clan-core/";
                }
              ];
            }
          ];
        }
      ];

      widgets = [
        {
          datetime = {
            locale = "de";
            format = {
              dateStyle = "short";
              timeStyle = "short";
              hour12 = false;
            };
          };
        }
      ];

      customCSS = ''
        #bookmarks {
          border-top: 1px solid rgba(255, 255, 255, 0.1);
          padding-top: 1rem;
          margin-top: 1rem;
        }
      '';
    };
  };
}

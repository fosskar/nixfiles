{
  flake.modules.nixos.homepage = _: {
    services.homepage-dashboard = {
      settings.quicklaunch = {
        searchDescriptions = true;
        hideInternetSearch = false;
        showSearchSuggestions = true;
        hideVisitURL = false;
        provider = "custom";
        url = "https://search.nx3.eu/search?q=";
      };

      # layout ordering and column config
      settings.layout = [
        {
          infrastructure = {
            header = true;
            style = "row";
            columns = 2;
          };
        }
        {
          media = {
            header = true;
          };
        }
        {
          tools = {
            header = true;
          };
        }
        {
          monitoring = {
            header = true;
            style = "column";
          };
        }
        {
          network = {
            header = true;
          };
        }
        {
          code = {
            header = true;
          };
        }
        {
          security = {
            header = true;
          };
        }
        {
          files = {
            header = true;
          };
        }
        {
          "llm" = {
            header = true;
          };
        }
        {
          communication = {
            header = true;
          };
        }
        {
          "arr-stack" = {
            header = true;
            columns = 2;
            initiallyCollapsed = true;
          };
        }
      ];

      # services on other machines — can't auto-register cross-machine
      serviceGroups = {
        "network" = [
          {
            "OpenWrt Router" = {
              href = "https://192.168.10.1";
              icon = "openwrt.svg";
            };
          }
          {
            "OpenWrt AP" = {
              href = "https://192.168.10.2";
              icon = "openwrt.svg";
            };
          }
          {
            "AdGuard Home" = {
              href = "http://192.168.10.1:8080";
              icon = "adguard-home.svg";
            };
          }
        ];
        "infrastructure" = [
          {
            "JetKVM HA" = {
              href = "http://jetkvm-ha.lan";
              icon = "mdi-console";
              siteMonitor = "http://192.168.10.30";
            };
          }
          {
            "JetKVM nixworker" = {
              href = "http://192.168.20.211";
              icon = "mdi-console";
              siteMonitor = "http://192.168.20.211";
            };
          }
          {
            "Nixbox BMC" = {
              href = "https://192.168.20.205";
              icon = "mdi-server-network";
              siteMonitor = "https://192.168.20.205";
            };
          }
          {
            "HP Printer" = {
              href = "http://192.168.10.153";
              icon = "mdi-printer";
            };
          }
        ];
        "code" = [
          {
            "Home Assistant" = {
              href = "http://homeassistant.lan:8123";
              icon = "home-assistant.svg";
              siteMonitor = "http://homeassistant.lan:8123";
            };
          }
        ];
        "files" = [
          {
            # no siteMonitor: local-only gui port
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
          search = {
            provider = "custom";
            url = "https://search.nx3.eu/search?q=";
            target = "_blank";
            showSearchSuggestions = true;
          };
        }
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

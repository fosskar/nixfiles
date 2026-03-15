{
  self,
  inputs,
  ...
}:
let
  inherit (inputs.nixpkgs) lib;
  mylib = import "${self}/lib" { inherit lib self; };
in
{
  flake.clan = {
    inherit self;
    specialArgs = {
      inherit inputs mylib;
    };

    meta = {
      name = "nixfiles";
      domain = "s";
      description = "personal nix infrastructure";
    };

    secrets.age.plugins = [
      "age-plugin-yubikey"
      #"age-plugin-tpm"
    ];

    inventory = {
      machines = {
        clawbox = {
          tags = [
            "server"
            "home"
            "ai"
          ];
        };

        hm-nixbox = {
          tags = [
            "server"
            "home"
          ];
        };

        hzc-pango = {
          tags = [
            "server"
            "hetzner"
          ];
        };

        simon-desktop = {
          tags = [
            "desktop"
            "home"
            "workstation"
          ];
        };

        lpt-titan = {
          tags = [
            "laptop"
            "home"
            "workstation"
          ];
        };
      };

      instances = {
        emergency-access = {
          module = {
            name = "emergency-access";
            input = "clan-core";
          };
          roles.default.tags.nixos = { };
        };

        sshd = {
          module = {
            name = "sshd";
            input = "clan-core";
          };
          roles.server = {
            tags.all = { };
            settings = {
              authorizedKeys = {
                simon = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID3AsDe157avF+iFa1TavZHwjDpugyePDqJ6gaRNzGIA openpgp:0xDA6712BE";
              };
            };
          };
          roles.client = {
            tags.all = { };
            settings = {
              certificate.searchDomains = [
                "lan"
                "local"
                "nx3.eu"
              ];
            };
          };
        };

        root-user = {
          module = {
            name = "users";
            input = "clan-core";
          };
          roles.default.tags.all = { };
          roles.default.settings = {
            user = "root";
            prompt = true;
            share = true;
          };
        };

        simon-user = {
          module = {
            name = "users";
            input = "clan-core";
          };

          roles.default = {
            machines.simon-desktop = { };
            machines.lpt-titan = { };
            settings = {
              user = "simon";
              share = true;
              groups = [
                "wheel"
                "input"
              ];
            };
            extraModules = [ "${self}/users/simon" ];
          };
        };

        monitoring = {
          module = {
            name = "monitoring";
            input = "self";
          };

          roles = {
            client.tags = [ "server" ];

            server.machines."hm-nixbox".settings = {
              dashboardsDir = ./hm-nixbox/dashboards;
              exporter = {
                enable = true;
                enableZfsExporter = true;
              };
              extraTelegrafTargets = [ "openwrt.lan:9273" ];
              extraScrapeConfigs = [
                {
                  job_name = "openwrt-node-exporter";
                  static_configs = [
                    {
                      targets = [ "openwrt.lan:9100" ];
                      labels.type = "node-exporter";
                    }
                  ];
                }
              ];
            };

            # hm-nixbox has richer local telemetry needs
            client.machines."hm-nixbox".settings.plugins = [
              "system"
              "systemd"
              "zfs"
              "upsd"
              "sensors"
              "smart"
              "postgresql"
            ];

          };
        };

        beszel = {
          module = {
            name = "beszel";
            input = "self";
          };

          roles = {
            client.tags = [ "server" ];
            server.machines."hm-nixbox" = { };
          };
        };

        clan-cache = {
          roles.default.tags.all = { };
          module = {
            name = "trusted-nix-caches";
            input = "clan-core";
          };
        };

        garage = {
          roles.default.machines."hm-nixbox" = { };
        };

        #mycelium = {
        #  roles.peer.tags.all = { };
        #};

        yggdrasil = {
          roles.default.tags.all = { };
        };

        tor = {
          roles.server.tags.nixos = { };
        };

        data-mesher = {
          module = {
            name = "data-mesher";
            input = "clan-core";
          };
          roles.default = {
            tags.all = { };
            settings = {
              interfaces = [
                "ygg"
                "wireguard"
              ];
            };
          };
          roles.bootstrap.machines = {
            hm-nixbox = { };
            hzc-pango = { };
          };
        };

        dm-dns = {
          module = {
            name = "dm-dns";
            input = "clan-core";
          };
          roles.default.tags.all = { };
          roles.push.machines = {
            hm-nixbox = { };
            hzc-pango = { };
          };
        };

        netbird = {
          module.input = "self";
          module.name = "netbird";

          roles.server.machines."hzc-pango".settings = {
            domain = "nb.fosskar.eu";
            proxyDomain = "fosskar.eu";
            port = 51821;
          };
          roles.client = {
            tags.all = { };
            machines."hm-nixbox".settings.routingFeatures = "server";
          };
        };

        wireguard = {
          module.name = "wireguard";
          module.input = "clan-core";
          roles.controller.machines."hzc-pango".settings = {
            endpoint = "138.201.155.21";
            port = 51820; # default
          };
          roles.peer.machines = {
            hm-nixbox.settings = { };
            simon-desktop.settings = { };
            lpt-titan.settings = { };
            clawbox.settings = { };
          };
        };

        #rosenpass = {
        #  module.name = "rosenpass";
        #  module.input = "self";
        #  roles.peer.machines = {
        #    hzc-pango.settings = {
        #      listenPort = 9999;
        #      endpoint = "138.201.155.21:9999";
        #    };
        #    hm-nixbox.settings = { };
        #    simon-desktop.settings = { };
        #    lpt-titan.settings = { };
        #    clawbox.settings = { };
        #  };
        #};

        # export IPs so yggdrasil peers via explicit connection (no multicast)
        internet = {
          roles.default.machines = {
            clawbox.settings.host = "192.168.10.90";
            hzc-pango.settings.host = "138.201.155.21";
            hm-nixbox.settings.host = "192.168.10.80";
            simon-desktop.settings.host = "192.168.10.200";
            lpt-titan.settings.host = "192.168.10.202";
          };
        };

        syncthing = {
          module = {
            name = "syncthing";
            input = "clan-core";
          };
          roles.peer = {
            machines.simon-desktop = { };
            machines.lpt-titan = { };
            settings = {
              folders = {
                # add folders here, e.g.:
                documents = {
                  path = "/home/simon/documents";
                  type = "sendreceive";
                };
                #zen-browser = {
                #  path = "/home/simon/.zen";
                #  type = "sendreceive";
                #};
              };
            };
          };
        };

        server-module = {
          module.name = "importer";
          roles.default = {
            tags.server = { };
            extraModules = [ "${self}/modules/profiles/server" ];
          };
        };

        workstation-module = {
          module.name = "importer";
          roles.default = {
            tags.workstation = { };
            extraModules = [ "${self}/modules/profiles/workstation" ];
          };
        };

        wifi = {
          module = {
            name = "wifi";
            input = "clan-core";
          };
          roles.default.machines.lpt-titan = {
            settings.networks = {
              home = { };
              # add more networks as needed, e.g.:
              # mobile = { autoConnect = false; };
            };
          };
        };

        ncps = {
          module = {
            name = "ncps";
            input = "clan-core";
          };
          roles = {
            server.machines."hm-nixbox".settings = {
              caches = [
                "https://cache.nixos.org"
                "https://nix-community.cachix.org"
                "https://hyprland.cachix.org"
                "https://cosmic.cachix.org"
                "https://nixpkgs-unfree.cachix.org"
                "https://nix-gaming.cachix.org"
              ];
              publicKeys = [
                "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
                "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
                "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
                "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE="
                "nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs="
                "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
              ];
            };
            client.machines = {
              simon-desktop.settings = { };
              lpt-titan.settings = { };
              clawbox.settings = { };
              hzc-pango.settings = { };
            };
          };
        };

        borgbackup = {
          module = {
            name = "borgbackup";
            input = "clan-core";
          };
          roles = {
            client.machines = {
              "hzc-pango".settings = {
                startAt = "*-*-* 04:00:00";
                exclude = [
                  "/var/cache"
                  "/var/log"
                  "/var/tmp"
                  "*.pyc"
                  "*.o"
                  "*/node_modules/*"
                ];
                destinations = {
                  "storagebox" = {
                    repo = "u499127-sub1@u499127.your-storagebox.de:/./hzc-pango";
                    rsh = "ssh -oPort=23 -i /run/secrets/vars/borgbackup/borgbackup.ssh -o StrictHostKeyChecking=accept-new -o IdentitiesOnly=yes";
                  };
                };
              };
              "hm-nixbox".settings = {
                startAt = "*-*-* 03:00:00";
                exclude = [
                  "/var/cache"
                  "/var/log"
                  "/var/lib/postgresql"
                  "/var/tmp"
                  "*.pyc"
                  "*.o"
                  "*/node_modules/*"
                ];
                destinations = {
                  "storagebox" = {
                    repo = "u499127-sub1@u499127.your-storagebox.de:/./hm-nixbox";
                    rsh = "ssh -oPort=23 -i /run/secrets/vars/borgbackup/borgbackup.ssh -o StrictHostKeyChecking=accept-new -o IdentitiesOnly=yes";
                  };
                };
              };
            };
            server.machines = { };
          };
        };
      };
    };
  };
}

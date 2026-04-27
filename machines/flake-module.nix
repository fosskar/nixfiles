{
  self,
  inputs,
  config,
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

    #vars.settings.age.postQuantum = true;

    #vars.settings.secretStore = "age";
    #vars.settings.recipients.default = [
    #  "age1yubikey1qv60kmnf4u6r09xxvgu8k4srgt9sq4fyh8vy65s77dce656srgadztwdl2r"
    #];

    secrets.age.plugins = [
      "age-plugin-yubikey"
      #"age-plugin-tpm"
    ];

    inventory = {
      machines = {
        "crowbox" = {
          tags = [
            "server"
            "home"
            "ai"
          ];
        };

        "nixbox" = {
          tags = [
            "server"
            "home"
          ];
        };

        "gateway" = {
          tags = [
            "server"
            "hetzner"
          ];
        };

        "lpt-titan" = {
          tags = [
            "laptop"
            "home"
            "workstation"
          ];
        };

        "nixworker" = {
          tags = [
            "server"
            "home"
            "remote-builder"
          ];
        };

        "simon-desktop" = {
          tags = [
            "workstation"
            "home"
          ];
        };
      };

      instances = {
        ## core / access

        metadata = {
          module.name = "importer";
          roles.default = {
            tags.all = { };
            extraModules = [ config.flake.modules.generic.domains ];
          };
        };

        base-common = {
          module.name = "importer";
          roles.default = {
            tags.nixos = { };
            extraModules = [ config.flake.modules.nixos.base ];
          };
        };

        server-common = {
          module.name = "importer";
          roles.default = {
            tags.server = { };
            extraModules = with config.flake.modules.nixos; [
              inputs.srvos.nixosModules.server
              server
            ];
          };
        };

        workstation-common = {
          module.name = "importer";
          roles.default = {
            tags.workstation = { };
            extraModules = with config.flake.modules.nixos; [
              inputs.srvos.nixosModules.desktop
              workstation
              yubikey
              niri
            ];
          };
        };

        laptop-common = {
          module.name = "importer";
          roles.default = {
            tags.laptop = { };
            extraModules = with config.flake.modules.nixos; [
              laptopPower
              fprint
            ];
          };
        };

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
            machines."simon-desktop" = { };
            machines."lpt-titan" = { };
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

        clan-cache = {
          roles.default.tags.all = { };
          module = {
            name = "trusted-nix-caches";
            input = "clan-core";
          };
        };

        ## networking

        # export IPs so yggdrasil peers via explicit connection (no multicast)
        internet = {
          roles.default.machines = {
            "crowbox".settings.host = "192.168.10.240";
            "gateway".settings.host = "138.201.155.21";
            "nixbox".settings.host = "192.168.10.200";
            "nixworker".settings.host = "192.168.10.210";
            "simon-desktop".settings.host = "192.168.10.100";
            "lpt-titan".settings.host = "192.168.10.150";
          };
        };

        wireguard = {
          module.name = "wireguard";
          module.input = "clan-core";

          roles.controller.machines."gateway".settings = {
            endpoint = "138.201.155.21";
            port = 51820; # default
          };
          roles.peer.machines = {
            "nixbox".settings = { };
            "simon-desktop".settings = { };
            "lpt-titan".settings = { };
            "crowbox".settings = { };
            "nixworker".settings = { };
          };
        };

        yggdrasil = {
          roles.default.tags.all = { };
        };

        netbird = {
          module.name = "netbird";
          module.input = "self";

          roles.server.machines."gateway".settings = {
            domain = "nb.fosskar.eu";
            proxyDomain = "proxy.fosskar.eu";
            port = 51821;
          };
          roles.client = {
            tags.all = { };
            machines."nixbox".settings.routingFeatures = "server";
          };
        };

        tor = {
          roles.server.tags.nixos = { };
        };

        #mycelium = {
        #  roles.peer.tags.all = { };
        #};

        #rosenpass = {
        #  module.name = "rosenpass";
        #  module.input = "self";
        #  roles.peer.machines = {
        #    gateway.settings = {
        #      listenPort = 9999;
        #      endpoint = "138.201.155.21:9999";
        #    };
        #    nixbox.settings = { };
        #    simon-desktop.settings = { };
        #    lpt-titan.settings = { };
        #    crowbox.settings = { };
        #  };
        #};

        # TODO: re-enable when clan networking fallback is fixed
        # see: https://git.clan.lol/clan/clan-core/issues/6964
        # dm-dns exports break networks_from_flake() (KeyError: 'peer')
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
            nixbox = { };
            gateway = { };
          };
        };

        dm-dns = {
          module = {
            name = "dm-dns";
            input = "clan-core";
          };
          roles.default.tags.all = { };
          roles.push.machines = {
            nixbox = { };
            gateway = { };
          };
        };

        ## workstation / user-facing

        wifi = {
          module = {
            name = "wifi";
            input = "clan-core";
          };
          roles.default.machines."lpt-titan" = {
            settings.networks = {
              home = { };
            };
          };
        };

        localsend = {
          module = {
            name = "localsend";
            input = "clan-community";
          };
          roles.default.tags.workstation = { };
        };

        #syncthing = {
        #  module = {
        #    name = "syncthing";
        #    input = "clan-core";
        #  };
        #  roles.peer = {
        #    machines."simon-desktop" = { };
        #    machines."lpt-titan" = { };
        #    settings = {
        #      folders = {
        #        # add folders here, e.g.:
        #        documents = {
        #          path = "/home/simon/documents";
        #          type = "sendreceive";
        #        };
        #        #zen-browser = {
        #        #  path = "/home/simon/.zen";
        #        #  type = "sendreceive";
        #        #};
        #      };
        #    };
        #  };
        #};

        ## monitoring

        monitoring = {
          module = {
            name = "monitoring";
            input = "self";
          };

          roles = {
            server.machines."nixbox".settings = {
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
            client.tags = [ "server" ];
          };
        };

        beszel = {
          module = {
            name = "beszel";
            input = "self";
          };

          roles = {
            client.tags = [ "server" ];
            client.machines."nixbox".settings = {
              sensors = "-nct6798_cputin,-nct6798_auxtin0,-nct6798_auxtin2,-nct6798_auxtin4";
              filesystem = "/persist";
              extraFilesystems = "/__Root,/nix__Nix,/boot__Boot,/boot-fallback__BootFallback,/tank__Tank,/tank/apps__Apps,/tank/media__Media,/tank/shares__Shares,/tank/backup__Backup";
              smartDevices = "/dev/nvme0,/dev/nvme1,/dev/sda,/dev/sdb,/dev/sdc,/dev/sdd,/dev/sde,/dev/sdf,/dev/sdg";
            };
            server.machines."nixbox" = { };
          };
        };

        # infra / storage / build

        garage = {
          roles.default.machines."nixbox" = { };
        };

        remote-builder = {
          module = {
            name = "remote-builder";
            input = "self";
          };
          roles = {
            builder.machines."nixworker" = { };
            client.machines = {
              "simon-desktop" = { };
              "lpt-titan" = { };
              "nixbox" = { };
              "crowbox" = { };
              "gateway" = { };
            };
          };
        };

        harmonia = {
          module = {
            name = "harmonia";
            input = "self";
          };
          roles = {
            server.machines."nixworker" = { };
            client.machines = {
              "simon-desktop" = { };
              "lpt-titan" = { };
              "nixbox" = { };
              "crowbox" = { };
              "gateway" = { };
            };
          };
        };

        ncps = {
          module = {
            name = "ncps";
            input = "clan-core";
          };
          roles = {
            server.machines."nixworker".settings = {
              caches = [
                "https://cache.nixos.org"
                "https://nix-community.cachix.org"
                "https://nix-gaming.cachix.org"
                "https://numtide.cachix.org"
              ];
              publicKeys = [
                "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
                "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
                "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
                "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
              ];
            };
            client.tags.all = { };
          };
        };

        # backups

        snapshot-backup = {
          module = {
            name = "snapshot-backup";
            input = "self";
          };
          roles.client.machines = {
            "gateway".settings = {
              snapshotType = "btrfs";
              folders = [ "/persist" ];
            };
            "nixbox".settings = {
              snapshotType = "zfs";
              folders = [
                "/tank/apps"
                "/tank/backup"
                "/tank/shares"
              ];
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
              "gateway".settings = {
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
                    repo = "u499127-sub1@u499127.your-storagebox.de:/./gateway";
                    rsh = "ssh -oPort=23 -i /run/secrets/vars/borgbackup/borgbackup.ssh -o StrictHostKeyChecking=accept-new -o IdentitiesOnly=yes";
                  };
                };
              };
              "nixbox".settings = {
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
                    repo = "u499127-sub1@u499127.your-storagebox.de:/./nixbox";
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

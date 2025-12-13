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
      description = "personal nix infrastructure";
    };

    secrets.age.plugins = [
      "age-plugin-yubikey"
      "age-plugin-tpm"
    ];

    inventory = {
      machines = {
        hzc-pango = {
          deploy.targetHost = "root@138.201.155.21";
          tags = [
            "server"
            "hetzner"
          ];
        };

        simon-desktop = {
          deploy.targetHost = "root@192.168.10.200";
          tags = [
            "desktop"
            "home"
          ];
        };

        hm-nixbox = {
          deploy.targetHost = "root@192.168.10.80";
          tags = [
            "server"
            "home"
          ];
        };
      };

      instances = {
        admin = {
          roles.default = {
            tags.all = { };
            settings.allowedKeys = {
              simon = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID3AsDe157avF+iFa1TavZHwjDpugyePDqJ6gaRNzGIA openpgp:0xDA6712BE";
            };
          };
        };

        simon-user = {
          module = {
            name = "users";
            input = "clan-core";
          };

          roles.default = {
            tags.desktop = { };

            machines.simon-desktop = { };

            settings = {
              user = "simon";
              groups = [
                "audio"
                "disk"
                "docker"
                "gamemode"
                "input"
                "networkmanager"
                "video"
                "wheel"
                "power"
                "podman"
                "git"
                "qemu-libvirtd"
                "kvm"
                "network"
                "dialout"
                "plugdev"
              ];
            };
          };
        };

        clan-cache = {
          roles.default.tags.all = { };
          module = {
            name = "trusted-nix-caches";
            input = "clan-core";
          };
        };

        yggdrasil = {
          roles.default.tags.all = { };
        };

        # export VPS public IP so yggdrasil peers via explicit connection (no multicast)
        internet = {
          roles.default.machines.hzc-pango = {
            settings.host = "138.201.155.21";
          };
        };

        server-module = {
          module.name = "importer";
          roles.default = {
            tags.server = { };
            extraModules = [ "${self}/modules/server" ];
          };
        };

        desktop-module = {
          module.name = "importer";
          roles.default = {
            tags.desktop = { };
            extraModules = [ "${self}/modules/desktop" ];
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
                destinations = {
                  "storagebox" = {
                    repo = "u499127-sub1@u499127.your-storagebox.de:/./hzc-pango";
                    rsh = "ssh -oPort=23 -i /run/secrets/vars/borgbackup/borgbackup.ssh -o StrictHostKeyChecking=accept-new -o IdentitiesOnly=yes";
                  };
                };
              };
              "hm-nixbox".settings = {
                startAt = "*-*-* 03:00:00";
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

        #matrix-synapse = {
        #  roles.default.machines."hm-nixbox".settings = {
        #    acmeEmail = "admin@osscar.me";
        #    server_tld = "osscar.me";
        #    app_domain = "matrix.osscar.me";
        #    users = {
        #      admin = {
        #        admin = true;
        #      };
        #      simon = {
        #        admin = true;
        #      };
        #    };
        #  };
        #};
      };
    };
  };
}

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
          roles.default.tags.all = { };
          roles.default.settings.allowedKeys = {
            simon = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID3AsDe157avF+iFa1TavZHwjDpugyePDqJ6gaRNzGIA openpgp:0xDA6712BE";
          };
        };

        simon-user = {
          module.name = "users";
          module.input = "clan-core";

          roles.default.tags.desktop = { };
          roles.default.machines.simon-desktop = { };

          roles.default.settings = {
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

        clan-cache = {
          roles.default.tags.all = { };
          module = {
            name = "trusted-nix-caches";
            input = "clan-core";
          };
        };

        server-module = {
          module.name = "importer";
          roles.default.tags.server = { };
          roles.default.extraModules = [ "${self}/modules/server" ];
        };

        desktop-module = {
          module.name = "importer";
          roles.default.tags.desktop = { };
          roles.default.extraModules = [ "${self}/modules/desktop" ];
        };
      };
    };
  };
}

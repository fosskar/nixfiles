{ self, inputs, ... }:
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
      name = "nixinfra";
      description = "personal nix infrastructure";
    };

    secrets.age.plugins = [ "age-plugin-yubikey" ];

    inventory = {
      machines = {
        # lxc containers on px-prd1
        arr.tags = [
          "px-prd1"
          "lxc"
        ];
        backup.tags = [
          "px-prd1"
          "lxc"
        ];
        dashboard.tags = [
          "px-prd1"
          "lxc"
        ];
        fileserver.tags = [
          "px-prd1"
          "lxc"
        ];
        gateway.tags = [
          "px-prd1"
          "lxc"
        ];
        immich.tags = [
          "px-prd1"
          "lxc"
        ];
        llm.tags = [
          "px-prd1"
          "lxc"
        ];
        media.tags = [
          "px-prd1"
          "lxc"
        ];
        monitoring.tags = [
          "px-prd1"
        ];
        nextcloud.tags = [
          "px-prd1"
          "lxc"
        ];
        oidc.tags = [
          "px-prd1"
          "lxc"
        ];
        paperless.tags = [
          "px-prd1"
          "lxc"
        ];
        reverseproxy.tags = [
          "px-prd1"
          "lxc"
        ];
        vaultwarden.tags = [
          "px-prd1"
          "lxc"
        ];

        # vps on hetzner cloud
        hzc-pango.tags = [
          "hetzner"
          "vm"
        ];

        # desktop deployments
        simon-desktop = {
          deploy.targetHost = "root@192.168.10.200";
          tags = [
            "desktop"
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

          roles.default.tags.desktop = { };

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

        #emergency-access = {
        #  roles.default.tags."all" = { };
        #};

        packages = {
          roles.default.tags.all = { };
          roles.default.settings = {
            packages = [
              "curl"
              "dnsutils"
              "gitMinimal"
            ];
          };
        };

        # trusted nix caches
        clan-cache = {
          roles.default.tags.all = { };
          module = {
            name = "trusted-nix-caches";
            input = "clan-core";
          };
        };

        internet = {
          roles.default.machines = {
            backup.settings.host = "10.0.0.98";
            gateway.settings.host = "10.0.0.100";
            reverseproxy.settings.host = "10.0.0.101";
            monitoring.settings.host = "10.0.0.102";
            dashboard.settings.host = "10.0.0.103";
            fileserver.settings.host = "10.0.0.104";
            oidc.settings.host = "10.0.0.105";
            llm.settings.host = "10.0.0.106";
            immich.settings.host = "10.0.0.107";
            paperless.settings.host = "10.0.0.108";
            vaultwarden.settings.host = "10.0.0.109";
            arr.settings.host = "10.0.0.110";
            media.settings.host = "10.0.0.111";
            nextcloud.settings.host = "10.0.0.112";
            hzc-pango.settings.host = "138.201.155.21";
          };
        };
      };
    };
  };
}

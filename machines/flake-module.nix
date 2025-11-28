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
        # lxc containers on px-prd1
        arr = {
          deploy.targetHost = "root@10.0.0.110";
          tags = [
            "px-prd1"
            "lxc"
          ];
        };
        backup = {
          deploy.targetHost = "root@10.0.0.98";
          tags = [
            "px-prd1"
            "lxc"
          ];
        };
        dashboard = {
          deploy.targetHost = "root@10.0.0.103";
          tags = [
            "px-prd1"
            "lxc"
          ];
        };
        fileserver = {
          deploy.targetHost = "root@10.0.0.104";
          tags = [
            "px-prd1"
            "lxc"
          ];
        };
        gateway = {
          deploy.targetHost = "root@10.0.0.100";
          tags = [
            "px-prd1"
            "lxc"
          ];
        };
        immich = {
          deploy.targetHost = "root@10.0.0.107";
          tags = [
            "px-prd1"
            "lxc"
          ];
        };
        llm = {
          deploy.targetHost = "root@10.0.0.106";
          tags = [
            "px-prd1"
            "lxc"
          ];
        };
        media = {
          deploy.targetHost = "root@10.0.0.111";
          tags = [
            "px-prd1"
            "lxc"
          ];
        };
        monitoring = {
          deploy.targetHost = "root@10.0.0.102";
          tags = [
            "px-prd1"
          ];
        };
        nextcloud = {
          deploy.targetHost = "root@10.0.0.112";
          tags = [
            "px-prd1"
            "lxc"
          ];
        };
        oidc = {
          deploy.targetHost = "root@10.0.0.105";
          tags = [
            "px-prd1"
            "lxc"
          ];
        };
        paperless = {
          deploy.targetHost = "root@10.0.0.108";
          tags = [
            "px-prd1"
            "lxc"
          ];
        };
        reverseproxy = {
          deploy.targetHost = "root@10.0.0.101";
          tags = [
            "px-prd1"
            "lxc"
          ];
        };
        vaultwarden = {
          deploy.targetHost = "root@10.0.0.109";
          tags = [
            "px-prd1"
            "lxc"
          ];
        };

        # vps on hetzner cloud
        hzc-pango = {
          deploy.targetHost = "root@138.201.155.21";
          tags = [
            "hetzner"
            "vm"
          ];
        };

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
      };
    };
  };
}

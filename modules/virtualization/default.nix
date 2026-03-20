{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.nixfiles.virtualization;
in
{
  # --- options ---

  options.nixfiles.virtualization = {
    docker = {
      enable = lib.mkEnableOption "docker container runtime";
    };

    podman = {
      enable = lib.mkEnableOption "podman container runtime";
      dockerCompat = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "enable docker cli compatibility for podman";
      };
    };

    libvirt = {
      enable = lib.mkEnableOption "libvirt/qemu virtualization";
    };
  };

  # --- service ---

  config = lib.mkMerge [
    (lib.mkIf cfg.docker.enable {
      users.groups.docker.members = config.users.groups.wheel.members;
      virtualisation.docker.enable = true;
    })

    (lib.mkIf cfg.podman.enable {
      users.groups.podman.members = config.users.groups.wheel.members;
      virtualisation.podman = {
        enable = true;
        inherit (cfg.podman) dockerCompat;
      };
      environment.systemPackages = [
        pkgs.dive # inspect container image layers
        pkgs.podman-tui # terminal UI for managing containers
      ];
    })

    (lib.mkIf cfg.libvirt.enable {
      virtualisation.libvirtd = {
        enable = true;
        qemu = {
          package = pkgs.qemu_kvm;
          runAsRoot = true;
        };
      };
    })
  ];
}

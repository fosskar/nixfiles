{
  mylib,
  config,
  ...
}:
{
  imports = [
    ../../modules/gaming
    ../../modules/yubikey
    ../../modules/power
    ../../modules/gpu
    ../../modules/cpu
    ../../modules/filesystems/btrfs.nix
    ../../modules/virtualization
    ../../modules/dms
    ../../modules/niri
    ../../modules/persistence
    ../../modules/agent-desktop
    ../../modules/arbor
    ../../modules/t3code
  ]
  ++ mylib.scanPaths ./. { };

  nixpkgs.hostPlatform = "x86_64-linux";

  networking.hostName = "simon-desktop";

  programs.nh.flake = "${config.users.users.simon.home}/code/nixfiles";

  clan.core.settings.machine-id.enable = true;

  # nixpkgs netbird ui wrapper currently fails on desktop file exec replacement
  services.netbird.ui.enable = false;

  nixfiles = {
    persistence = {
      enable = true;
      rollback = {
        type = "btrfs";
        deviceLabel = "nixos";
      };
    };

    audio.lowLatency.enable = true;
    yubikey.u2f.authfile = config.sops.secrets."u2f_keys".path;
    gpu.amd.enable = true;
    cpu.amd.enable = true;

    virtualization = {
      docker.enable = true;
      podman.enable = true;
    };

    gaming.starCitizen.enable = true;
  };
}

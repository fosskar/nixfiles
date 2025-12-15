{ mylib, config, ... }:
{

  imports = [
    ../../modules/tailscale
    ../../modules/gaming
    ../../modules/yubikey
    ../../modules/power
    ../../modules/gpu
    ../../modules/cpu
  ]
  ++ mylib.scanPaths ./. { };

  nixpkgs.hostPlatform = "x86_64-linux";

  networking.hostName = "simon-desktop";

  programs.nh.flake = "${config.users.users.simon.home}/code/nixfiles";

  nixfiles = {
    audio.lowLatency.enable = true;
    yubikey.u2f.authfile = config.sops.secrets."u2f_keys".path;

    gpu.amd.enable = true;
    cpu.amd.enable = true;
  };
}

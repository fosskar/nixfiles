{
  mylib,
  config,
  inputs,
  ...
}:
{
  imports = [
    inputs.nixos-hardware.nixosModules.framework-amd-ai-300-series
    ../../modules/tailscale
    ../../modules/yubikey
    ../../modules/power
    ../../modules/gpu
    ../../modules/cpu
    ../../modules/fingerprint
    ../../modules/dms
    ../../modules/niri
  ]
  ++ mylib.scanPaths ./. { };

  nixpkgs.hostPlatform = "x86_64-linux";

  networking.hostName = "lpt-titan";

  programs.nh.flake = "${config.users.users.simon.home}/code/nixfiles";

  clan.core.settings.machine-id.enable = true;

  nixfiles = {
    audio.lowLatency.enable = true;
    yubikey.u2f.authfile = config.sops.secrets."u2f_keys".path;
    gpu.amd.enable = true;
    cpu.amd.enable = true;
  };
}

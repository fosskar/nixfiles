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
    # ../../modules/lanzaboote  # TODO: enable after first boot + sbctl create-keys
    ../../modules/fprint
    ../../modules/bcachefs
    ../../modules/dms
    ../../modules/niri
    ../../modules/wifi
  ]
  ++ mylib.scanPaths ./. { };

  nixpkgs.hostPlatform = "x86_64-linux";

  networking.hostName = "lpt-titan";

  programs.nh.flake = "${config.users.users.simon.home}/code/nixfiles";

  clan.core.settings.machine-id.enable = true;

  nixfiles = {
    audio.lowLatency.enable = true;
    yubikey.u2f.authfile = config.sops.secrets."u2f_keys".path;
    wifi.credentials = {
      enable = true;
      ssid = "OWRT";
    };
    cpu.amd.enable = true;
    gpu.amd = {
      enable = true;
      # not needed for iGPU
      lact.enable = false;
      opencl.enable = false;
    };
    power = {
      logind.enable = true;
      powertop.enable = true;
      tuned = {
        enable = true;
        ppdSupport = true;
      };
    };
  };

  # skip nix-gc when on battery
  systemd.services.nix-gc.unitConfig.ConditionACPower = true;
}

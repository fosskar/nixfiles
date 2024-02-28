{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports = [inputs.nix-gaming.nixosModules.pipewireLowLatency];

  sound.enable = true;
  hardware.pulseaudio.enable = lib.mkForce false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;
    lowLatency = {
      enable = true;
      quantum = 256;
      rate = 44100;
    };
  };

  environment.systemPackages = with pkgs; [
    pavucontrol
    playerctl
    pulsemixer
    easyeffects
    pamixer
  ];
}

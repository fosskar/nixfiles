{ lib, pkgs, ... }:
let
  q = 64;
  r = 48000;
  qr = "64/48000";
in
{
  hardware.pulseaudio.enable = lib.mkForce false;
  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;
  };

  environment.systemPackages = with pkgs; [
    pavucontrol
    playerctl
    pamixer
  ];
}

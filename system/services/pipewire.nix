{
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports = [inputs.nix-gaming.nixosModules.pipewireLowLatency];

  sound.enable = true;
  hardware.pulseaudio.enable = lib.mkForce false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;
    lowLatency = {
      enable = true;
      quantum = 64;
      rate = 44100;
    };
    #extraConfig.pipewire = {
    #  "92-low-latency" = {
    #    "context.properties" = {
    #      "default.clock.rate" = 44100;
    #      "default.clock.allowed-rates" = [44100];
    #      "default.clock.quantum" = 64;
    #      "default.clock.min-quantum" = 64;
    #      "default.clock.max-quantum" = 64;
    #    };
    #  };
    #};
  };

  #environment.etc."wireplumber/wireplumber.conf.d/51-change-channels.conf".source = pkgs.writeText "51-change-channels.conf" ''
  #  monitor.alsa.rules = [
  #    {
  #      matches = [
  #        {
  #          node.name = "~alsa_output.usb-Focusrite_Scarlett_Solo_USB_Y7NY0CB223AE7B-00.*"
  #        }
  #      ]
  #      actions = {
  #        update-props = {
  #          audio.position  = "FR,FL"
  #        }
  #      }
  #    }
  #  ]
  #'';

  environment.systemPackages = with pkgs; [
    pavucontrol
    playerctl
    pamixer
  ];
}

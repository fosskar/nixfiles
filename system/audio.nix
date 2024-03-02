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
    #lowLatency = {
    #  enable = true;
    #  quantum = qr;
    #  rate = re;
    #};
    extraConfig.pipewire = {
      "92-low-latency" = {
        "context.properties" = {
          "default.clock.rate" = 44100;
          "default.clock.allowed-rates" = [44100];
          "default.clock.quantum" = 128;
          "default.clock.min-quantum" = 128;
          "default.clock.max-quantum" = 128;
        };
      };
    };
    #extraConfig.pipewire-pulse = {
    #  "99-low-latency" = {
    #    "context.modules" = [
    #      {
    #        "name" = "libpipewire-module-protocol-pulse";
    #        "args" = {
    #          "server.address" = ["unix:native"];
    #          "pulse.min.req" = "128/44100";
    #          "pulse.default.req" = "128/44100";
    #          "pulse.max.req" = "128/44100";
    #          "pulse.min.quantum" = "128/44100";
    #          "pulse.max.quantum" = "128/44100";
    #        };
    #      }
    #    ];
    #    "stream.properties" = {
    #      "node.latency" = "128/44100";
    #      "resample.quality" = 1;
    #    };
    #  };
    #};
  };

  environment.systemPackages = with pkgs; [
    pavucontrol
    playerctl
    pulsemixer
    easyeffects
    pamixer
  ];
}

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

    extraConfig.pipewire = {
      "99-low-latency" = {
        context = {
          properties.default.clock = {
            rate = r;
            allowed-rates = [
              44100
              48000
            ];
            quantum = q;
            min-quantum = q;
            max-quantum = q;
          };
          modules = [
            {
              name = "libpipewire-module-rtkit";
              flags = [
                "ifexists"
                "nofail"
              ];
              args = {
                nice.level = -15;
                rt = {
                  prio = 70;
                  time = {
                    soft = 200000;
                    hard = 200000;
                  };
                };
              };
            }
            {
              name = "libpipewire-module-protocol-pulse";
              args = {
                server.address = [ "unix:native" ];
                pulse = {
                  default.req = qr;
                  min = {
                    req = qr;
                    quantum = qr;
                    frag = qr;
                  };
                  max = {
                    req = qr;
                    quantum = qr;
                    frag = qr;
                  };
                };
              };
            }
          ];
          stream.properties = {
            node.latency = qr;
            resample.quality = 1;
          };
        };
      };
    };
  };

  security.rtkit.enable = true;

  environment.systemPackages = with pkgs; [
    pavucontrol
    playerctl
    pamixer
  ];
}

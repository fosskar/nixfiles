{ lib, pkgs, ... }:
let
  q = 32;
  r = 48000;
  qr = "32/48000";
in
{
  services = {
    pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
      jack.enable = false;
      wireplumber = {
        enable = true;
        extraConfig = {
          "98-alsa-low-latency" = {
            "monitor.alsa.rules" = [
              {
                matches = [
                  { "node.name" = "~alsa_output.*"; }
                ];
                actions = {
                  update-props = {
                    "audio.format" = "S24_3LE"; # S16_LE, S24_3LE, S32LE
                    "audio.rate" = r;
                    "audio.channels" = "2";
                    "api.alsa.period-size" = 512;
                    "api.alsa.period-num" = 3;
                  };
                };
              }
            ];
          };
          "10-disable-camera" = {
            "wireplumber.profiles" = {
              main."monitor.libcamera" = "disabled";
            };
          };
        };
      };
      extraConfig = {
        pipewire = {
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
                      prio = 88;
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
        pipewire-pulse."92-pulse-low-latency" = {
          context.modules = [
            {
              name = "libpipewire-module-protocol-pulse";
              args = {
                pulse = {
                  min = {
                    req = qr;
                    quantum = qr;
                  };
                  default.req = qr;
                  max = {
                    req = qr;
                    quantum = qr;
                  };
                };
              };
            }
          ];
          stream.properties = {
            node.latency = qr;
            resample.quality = 3;
          };
        };
      };
    };
    pulseaudio.enable = lib.mkForce false;
  };

  security.rtkit.enable = true;

  environment.systemPackages = with pkgs; [
    #pavucontrol # pulseaudio volume control keep as fallback
    pwvucontrol # pipewire volume control
    playerctl
    pamixer
  ];
}

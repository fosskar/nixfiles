{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.nixfiles.audio;
  qr = "${toString cfg.lowLatency.quantum}/${toString cfg.lowLatency.rate}";
in
{
  options.nixfiles.audio = {
    lowLatency = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "enable low-latency audio configuration for gaming/music production";
      };
      quantum = lib.mkOption {
        type = lib.types.int;
        default = 32;
        description = "pipewire quantum (buffer size) - lower = less latency but more CPU";
      };
      rate = lib.mkOption {
        type = lib.types.int;
        default = 48000;
        description = "sample rate in Hz";
      };
    };
  };

  config = {
    # add wheel users to audio group
    users.groups.audio.members = config.users.groups.wheel.members;

    # low-latency audio udev rules (rtc, hpet, cpu_dma_latency access for audio group)
    services.udev.extraRules = lib.mkIf cfg.lowLatency.enable ''
      KERNEL=="rtc0", GROUP="audio"
      KERNEL=="hpet", GROUP="audio"
      DEVPATH=="/devices/virtual/misc/cpu_dma_latency", OWNER="root", GROUP="audio", MODE="0660"
    '';

    services.pipewire = {
      enable = lib.mkDefault true;
      alsa = {
        enable = lib.mkDefault true;
        support32Bit = lib.mkDefault true;
      };
      pulse.enable = lib.mkDefault true;
      jack.enable = lib.mkDefault false;
      wireplumber = {
        enable = lib.mkDefault true;
        extraConfig = {
          "10-disable-camera" = {
            "wireplumber.profiles".main."monitor.libcamera" = "disabled";
          };
        }
        // lib.optionalAttrs cfg.lowLatency.enable {
          "98-alsa-low-latency" = {
            "monitor.alsa.rules" = [
              {
                matches = [
                  { "node.name" = "~alsa_output.*"; }
                ];
                actions = {
                  update-props = {
                    "audio.format" = "S24_3LE";
                    "audio.rate" = cfg.lowLatency.rate;
                    "audio.channels" = "2";
                    "api.alsa.period-size" = 512;
                    "api.alsa.period-num" = 3;
                  };
                };
              }
            ];
          };
        };
      };
      extraConfig = lib.mkIf cfg.lowLatency.enable {
        pipewire."99-low-latency" = {
          context = {
            properties.default.clock = {
              inherit (cfg.lowLatency) rate;
              allowed-rates = [
                44100
                48000
              ];
              inherit (cfg.lowLatency) quantum;
              min-quantum = cfg.lowLatency.quantum;
              max-quantum = cfg.lowLatency.quantum;
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

    services.pulseaudio.enable = lib.mkForce false;

    security.rtkit.enable = lib.mkDefault true;

    environment.systemPackages = with pkgs; [
      pwvucontrol
      playerctl
      pamixer
    ];
  };
}

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
    # srvos.desktop sets: pipewire.enable, alsa.enable, pulse.enable, rtkit.enable

    # add wheel users to audio group
    users.groups.audio.members = config.users.groups.wheel.members;

    services = {
      # low-latency audio udev rules (rtc, hpet, cpu_dma_latency access for audio group)
      udev.extraRules = lib.mkIf cfg.lowLatency.enable ''
        KERNEL=="rtc0", GROUP="audio"
        KERNEL=="hpet", GROUP="audio"
        DEVPATH=="/devices/virtual/misc/cpu_dma_latency", OWNER="root", GROUP="audio", MODE="0660"
      '';

      pipewire = {
        # srvos enables these, we add extras
        alsa.support32Bit = lib.mkDefault true;
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
                      #"audio.format" = "S24_3LE"; # can force pro-audio profile on some devices
                      "audio.rate" = cfg.lowLatency.rate;
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

      pulseaudio.enable = lib.mkForce false;
    };

    environment.systemPackages = with pkgs; [
      pwvucontrol
      playerctl
      pamixer
    ];
  };
}

{
  flake.modules.nixos.workstation =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    let
      rate = 48000;
      quantum = 32;
      qr = "${toString quantum}/${toString rate}";
    in
    {
      config = {
        users.groups.audio.members = config.users.groups.wheel.members;

        services = {
          udev.extraRules = ''
            KERNEL=="rtc0", GROUP="audio"
            KERNEL=="hpet", GROUP="audio"
            DEVPATH=="/devices/virtual/misc/cpu_dma_latency", OWNER="root", GROUP="audio", MODE="0660"
          '';

          pipewire = {
            alsa.support32Bit = lib.mkDefault true;
            jack.enable = lib.mkDefault false;
            wireplumber = {
              enable = lib.mkDefault true;
              extraConfig = {
                "10-disable-camera" = {
                  "wireplumber.profiles".main."monitor.libcamera" = "disabled";
                };
                "11-usb-audio-autoprofile" = {
                  "monitor.alsa.rules" = [
                    {
                      matches = [ { "device.bus" = "usb"; } ];
                      actions.update-props = {
                        "api.acp.auto-profile" = true;
                        "api.acp.auto-port" = true;
                      };
                    }
                  ];
                };
                "98-alsa-low-latency" = {
                  "monitor.alsa.rules" = [
                    {
                      matches = [
                        { "node.name" = "~alsa_output.*"; }
                      ];
                      actions = {
                        update-props = {
                          "audio.rate" = rate;
                          "api.alsa.period-size" = 512;
                          "api.alsa.period-num" = 3;
                        };
                      };
                    }
                  ];
                };
              };
            };
            extraConfig = {
              pipewire."99-low-latency" = {
                context = {
                  properties.default.clock = {
                    inherit rate quantum;
                    allowed-rates = [
                      44100
                      48000
                    ];
                    min-quantum = quantum;
                    max-quantum = quantum;
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
    };
}

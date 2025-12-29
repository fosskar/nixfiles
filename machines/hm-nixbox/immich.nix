{
  config,
  pkgs,
  lib,
  ...
}:
{
  nixfiles.nginx.vhosts.immich = {
    inherit (config.services.immich) port;
    extraConfig = "client_max_body_size 50G;";
  };

  services.immich = {
    enable = true;
    host = "127.0.0.1";
    port = 2283;
    mediaLocation = "/tank/apps/immich";
    secretsFile = config.sops.secrets."immich.env".path;

    openFirewall = false;

    accelerationDevices = [
      "/dev/dri/renderD128"
    ];

    database = {
      enable = true;
      createDB = true;
    };

    redis.enable = true;

    machine-learning = {
      enable = true;
      environment = {
        # fix opencl icd path for nixos
        OCL_ICD_VENDORS = "/run/opengl-driver/etc/OpenCL/vendors";

        LD_LIBRARY_PATH = builtins.concatStringsSep ":" [
          "${pkgs.python312Packages.openvino}/lib"
          "${pkgs.python312Packages.openvino}/lib/python3.12/site-packages/openvino"
        ];

        MPLCONFIGDIR = "/var/cache/immich-machine-learning";
        TRANSFORMERS_CACHE = "/var/cache/immich-machine-learning";
      };
    };

    settings = {
      server = {
        externalDomain = "https://immich.simonoscar.me";
        loginPageMessage = "henlo";
      };
      newVersionCheck.enabled = false;

      passwordLogin.enabled = true;

      ffmpeg.accel = "qsv";

      library = {
        scan = {
          enabled = false;
          cronExpression = "0 0 * * *";
        };
        watch.enabled = true;
      };
    };
  };

  users.users.immich.extraGroups = [
    "render"
    "video"
  ];

  systemd = {
    services = {
      immich-server = {
        serviceConfig = {
          PrivateDevices = lib.mkForce false; # disable sandboxing
          DeviceAllow = [
            "/dev/dri/card1 rw"
            "/dev/dri/renderD128 rw"
          ];
        };
      };
      immich-machine-learning = {
        serviceConfig = {
          PrivateDevices = lib.mkForce false; # disable sandboxing
          DeviceAllow = [ "/dev/dri/renderD128 rw" ];
        };
      };
    };
    tmpfiles.rules = [
      "d /var/cache/immich-machine-learning 0755 immich immich -"
    ];
  };
  environment = {
    systemPackages = with pkgs; [
      immich-go
    ];
  };
}

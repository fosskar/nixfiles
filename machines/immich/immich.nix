{
  config,
  pkgs,
  lib,
  ...
}:
{
  services.immich = {
    enable = true;
    host = "10.0.0.107";
    port = 2283;
    mediaLocation = "/mnt/immich";
    secretsFile = config.age.secrets.immich-envs.path;

    openFirewall = true;

    accelerationDevices = [
      "/dev/dri/renderD128"
    ];

    # enable local postgresql database
    database = {
      enable = true;
      createDB = true;
    };

    # enable redis (required for immich)
    redis.enable = true;

    # enable machine learning features
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
        externalDomain = "https://photos.simonoscar.me";
        loginPageMessage = "henlo";
      };
      newVersionCheck.enabled = false;

      passwordLogin.enabled = false;

      oauth = {
        enabled = true;
        issuerUrl = "https://auth.simonoscar.me";
        scope = "openid email profile";
        buttonText = "login with passkey";
        clientId._secret = config.age.secrets.immich-oauth-client-id.path;
        clientSecret._secret = config.age.secrets.immich-oauth-client-secret.path;
        autoRegister = true;
        autoLaunch = false;

        defaultStorageQuota = 100; # 100 GiB for users without the claim
      };

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

  # for shared bind-mounts
  users = {
    groups = {
      immich = {
        gid = 10000; # maps to host 110000 (storage_shared)
      };
      # shared group from fileserver (for correct display name)
      shared = {
        gid = 5000;
      };
    };
    users.immich = {
      isSystemUser = true;
      uid = 1107; # container 107 -> uid 1107 -> host 101107
      group = "immich";
      extraGroups = [
        "render"
        "video"
      ];
    };
  };
  systemd = {
    services = {
      # For video transcoding (QSV)
      immich-server = {
        serviceConfig = {
          PrivateDevices = lib.mkForce false; # disable sandboxing
          DeviceAllow = [
            "/dev/dri/card1 rw"
            "/dev/dri/renderD128 rw"
          ];
        };
      };
      # For ML inference (OpenVINO)
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

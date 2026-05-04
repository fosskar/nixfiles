{
  flake.modules.nixos.immich =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      serviceName = "immich";
      localHost = "${serviceName}.${config.domains.local}";
      publicHost = "${serviceName}.${config.domains.public}";
      listenAddress = "0.0.0.0";
      listenPort = 2283;
      listenUrl = "http://127.0.0.1:${toString listenPort}";

      # immich with openvino ML acceleration (inlined from old openvino.nix helper)
      immichPackage =
        let
          onnxruntime =
            (pkgs.onnxruntime.override {
              python3Packages = pkgs.python312Packages;
            }).overrideAttrs
              (oldAttrs: {
                buildInputs = (oldAttrs.buildInputs or [ ]) ++ [ pkgs.openvino ];

                nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [ pkgs.patchelf ];

                cmakeFlags = (oldAttrs.cmakeFlags or [ ]) ++ [
                  (lib.cmakeBool "onnxruntime_USE_OPENVINO" true)
                  (lib.cmakeFeature "OpenVINO_DIR" "${pkgs.openvino}/runtime/cmake")
                ];

                postFixup = (oldAttrs.postFixup or "") + ''
                  provider="''${!outputLib}/lib/libonnxruntime_providers_openvino.so"
                  if [ -e "$provider" ]; then
                    patchelf --add-rpath "${pkgs.openvino}/runtime/lib/intel64" "$provider"
                  fi
                '';

                doCheck = false;
              });

          python312 = pkgs.python312.override {
            packageOverrides = _pyFinal: pyPrev: {
              onnxruntime =
                (pyPrev.onnxruntime.override {
                  inherit onnxruntime;
                }).overrideAttrs
                  (oldAttrs: {
                    buildInputs = (oldAttrs.buildInputs or [ ]) ++ [ pkgs.openvino ];
                  });
              openvino = pyPrev.openvino.overrideAttrs (_: {
                pythonImportsCheck = [ ];
              });
            };
          };

          machineLearning =
            (pkgs.immich-machine-learning.override {
              python3 = python312;
            }).overrideAttrs
              (_: {
                doCheck = false;
              });

          immich = pkgs.immich.override {
            immich-machine-learning = machineLearning;
          };
        in
        immich.overrideAttrs (oldAttrs: {
          passthru = oldAttrs.passthru // {
            machine-learning = oldAttrs.passthru.machine-learning.overrideAttrs (_: {
              doCheck = false;
              doInstallCheck = false;
            });
          };
        });
    in
    {
      clan.core.vars.generators.immich = {
        files = {
          "oauth-client-secret-hash" = {
            owner = "authelia-main";
            group = "authelia-main";
          };
          "oauth-client-secret" = {
            owner = "immich";
            group = "immich";
          };
          "db-password.env" = {
            owner = "immich";
            group = "immich";
          };
        };

        runtimeInputs = with pkgs; [
          pwgen
          authelia
        ];
        script = ''
          SECRET=$(pwgen -s 64 1)
          authelia crypto hash generate pbkdf2 --password "$SECRET" | tail -1 | cut -d' ' -f2 > "$out/oauth-client-secret-hash"
          echo -n "$SECRET" > "$out/oauth-client-secret"

          if [ -f "$in/immich/db-password.env" ]; then
            cp "$in/immich/db-password.env" "$out/db-password.env"
          else
            echo "DB_PASSWORD=$(pwgen -s 32 1)" > "$out/db-password.env"
          fi
        '';
      };

      services.authelia.instances.main.settings.identity_providers.oidc.clients = [
        {
          client_id = "immich";
          client_name = "Immich";
          client_secret = "{{ secret \"${
            config.clan.core.vars.generators.immich.files."oauth-client-secret-hash".path
          }\" }}";
          public = false;
          consent_mode = "implicit";
          authorization_policy = "users";
          token_endpoint_auth_method = "client_secret_post";
          redirect_uris = [
            "https://${localHost}/auth/login"
            "https://${localHost}/user-settings"
            "https://${publicHost}/auth/login"
            "https://${publicHost}/user-settings"
            "app.immich:///oauth-callback"
          ];
          scopes = [
            "openid"
            "profile"
            "email"
            "groups"
          ];
          response_types = [ "code" ];
          grant_types = [ "authorization_code" ];
          claims_policy = "immich_policy";
        }
      ];

      services.immich = {
        enable = true;
        package = immichPackage;
        host = listenAddress;
        port = listenPort;
        mediaLocation = "/tank/apps/immich";
        secretsFile = config.clan.core.vars.generators.immich.files."db-password.env".path;

        openFirewall = false;

        accelerationDevices = [ "/dev/dri/renderD128" ];

        database = {
          enable = true;
          createDB = true;
        };

        redis.enable = true;

        machine-learning = {
          enable = true;
          environment = {
            OCL_ICD_VENDORS = "/run/opengl-driver/etc/OpenCL/vendors";

            LD_LIBRARY_PATH = builtins.concatStringsSep ":" [
              "${pkgs.openvino}/runtime/lib/intel64"
              "${pkgs.python312Packages.openvino}/lib"
              "${pkgs.python312Packages.openvino}/lib/python3.12/site-packages/openvino"
            ];

            MPLCONFIGDIR = "/var/cache/immich-machine-learning";
            TRANSFORMERS_CACHE = "/var/cache/immich-machine-learning";
          };
        };

        settings = {
          server = {
            externalDomain = "https://${localHost}";
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

          oauth = {
            enabled = true;
            autoRegister = true;
            autoLaunch = false;
            buttonText = "Login with Authelia";
            clientId = "immich";
            clientSecret._secret = config.clan.core.vars.generators.immich.files."oauth-client-secret".path;
            issuerUrl = "https://auth.${config.domains.public}/.well-known/openid-configuration";
            scope = "openid profile email groups";
            roleClaim = "immich_role";
          };
        };
      };

      users.users.immich.extraGroups = [
        "render"
        "video"
      ];

      services.homepage-dashboard.serviceGroups."Media" =
        lib.mkIf config.services.homepage-dashboard.enable
          [
            {
              "Immich" = {
                href = "https://${localHost}";
                icon = "immich.png";
                siteMonitor = listenUrl;
              };
            }
          ];

      services.gatus.settings.endpoints = lib.mkIf config.services.gatus.enable [
        {
          name = "Immich";
          url = "https://${localHost}";
          group = "Media";
          enabled = true;
          interval = "5m";
          conditions = [ "[STATUS] == 200" ];
          alerts = [ { type = "ntfy"; } ];
        }
      ];

      services.caddy.virtualHosts.${localHost}.extraConfig = ''
        reverse_proxy ${listenUrl}
                  request_body {
                    max_size 50GB
                  }
                
      '';

      clan.core.postgresql.enable = true;
      clan.core.postgresql.databases.immich = {
        create.enable = false;
        restore.stopOnRestore = [
          "immich-server.service"
          "immich-machine-learning.service"
          "redis-immich.service"
        ];
      };

      systemd = {
        services = {
          immich-server = {
            serviceConfig = {
              PrivateDevices = lib.mkForce false;
              DeviceAllow = [
                "/dev/dri/card1 rw"
                "/dev/dri/renderD128 rw"
              ];
            };
          };
          immich-machine-learning = {
            serviceConfig = {
              PrivateDevices = lib.mkForce false;
              DeviceAllow = [ "/dev/dri/renderD128 rw" ];
            };
          };
        };
        tmpfiles.rules = [
          "d /var/cache/immich-machine-learning 0755 immich immich -"
        ];
      };

      environment.systemPackages = [ pkgs.immich-go ];
    };
}

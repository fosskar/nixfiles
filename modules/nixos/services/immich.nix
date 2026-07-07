{
  flake.modules.nixos.immich =
    {
      flake-self,
      config,
      pkgs,
      ...
    }:
    let
      serviceName = "immich";
      localHost = "${serviceName}.${flake-self.domains.local}";
      publicHost = "${serviceName}.${flake-self.domains.public}";
      listenAddress = "0.0.0.0";
      listenPort = 2283;
      listenUrl = "http://127.0.0.1:${toString listenPort}";

      python3Cuda = pkgs.python3.override {
        packageOverrides = pyFinal: pyPrev: {
          onnxruntime = pyPrev.onnxruntime.override {
            onnxruntime = pkgs.onnxruntime.override {
              cudaSupport = true;
              python3Packages = pyFinal;
            };
          };
        };
      };

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

        runtimeInputs = [
          pkgs.pwgen
          pkgs.authelia
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
        package = pkgs.immich.override {
          immich-machine-learning = pkgs.immich-machine-learning.override { python3 = python3Cuda; };
        };
        host = listenAddress;
        port = listenPort;
        mediaLocation = "/tank/apps/immich";
        secretsFile = config.clan.core.vars.generators.immich.files."db-password.env".path;

        openFirewall = false;

        database = {
          enable = true;
          createDB = true;
        };

        redis.enable = true;

        # `null` will give access to all devices.
        # You may want to restrict this by using something like `[ "/dev/dri/renderD128" ]`
        accelerationDevices = [
          "/dev/nvidia0"
          "/dev/nvidiactl"
          "/dev/nvidia-uvm"
          "/dev/nvidia-uvm-tools"
        ];

        machine-learning = {
          enable = true;
          environment = {
            LD_LIBRARY_PATH = builtins.concatStringsSep ":" [
              "${python3Cuda.pkgs.onnxruntime}/lib"
              "${python3Cuda.pkgs.onnxruntime}/${python3Cuda.sitePackages}/onnxruntime/capi"
            ];
          };
        };

        settings = {
          server = {
            externalDomain = "https://${publicHost}";
            loginPageMessage = "henlo";
          };
          newVersionCheck.enabled = false;

          passwordLogin.enabled = true;

          ffmpeg.accel = "nvenc";

          library = {
            scan = {
              enabled = false;
              cronExpression = "0 0 * * *";
            };
            watch.enabled = true;
          };

          notifications.smtp = {
            enabled = true;
            from = "Immich <noreply@nx3.eu>";
            replyTo = "noreply@nx3.eu";
            transport = {
              ignoreCert = false;
              host = "smtp.mailbox.org";
              port = 587;
              secure = false;
              username._secret = config.clan.core.vars.generators.smtp.files.username.path;
              password._secret = config.clan.core.vars.generators.smtp.files.password.path;
            };
          };

          oauth = {
            enabled = true;
            autoRegister = true;
            autoLaunch = false;
            buttonText = "Login with Authelia";
            clientId = "immich";
            clientSecret._secret = config.clan.core.vars.generators.immich.files."oauth-client-secret".path;
            issuerUrl = "https://auth.${flake-self.domains.public}/.well-known/openid-configuration";
            scope = "openid profile email groups";
            roleClaim = "immich_role";
          };
        };
      };

      users.users.immich.extraGroups = [
        "render"
        "video"
      ];

      services.homepage-dashboard.services = [
        {
          "media" = [
            {
              "Immich" = {
                href = "https://${localHost}";
                icon = "immich.png";
                siteMonitor = listenUrl;
              };
            }
          ];
        }
      ];

      services.gatus.settings.endpoints = [
        {
          name = "Immich";
          url = "https://${localHost}";
          group = "Media";
          enabled = true;
          alerts = [ { type = "email"; } ];
          interval = "5m";
          conditions = [ "[STATUS] == 200" ];
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

      environment.systemPackages = [ pkgs.immich-go ];
    };
}

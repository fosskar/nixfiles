{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixfiles.immich;
  acmeDomain = config.nixfiles.acme.domain;
  inherit (config.nixfiles.authelia) publicDomain;
  serviceDomain = "immich.${acmeDomain}";
in
{
  options.nixfiles.immich = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "immich photo management";
    };
  };

  config = lib.mkIf cfg.enable {
    # generate immich secrets
    clan.core.vars.generators.immich = {
      files = {
        "oauth-client-secret-hash" = { };
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
        # oauth secret
        SECRET=$(pwgen -s 64 1)
        authelia crypto hash generate pbkdf2 --password "$SECRET" | tail -1 > "$out/oauth-client-secret-hash"
        echo -n "$SECRET" > "$out/oauth-client-secret"

        # db password - generate only if not migrated manually
        if [ -f "$in/immich/db-password.env" ]; then
          cp "$in/immich/db-password.env" "$out/db-password.env"
        else
          echo "DB_PASSWORD=$(pwgen -s 32 1)" > "$out/db-password.env"
        fi
      '';
    };

    # register oidc client with authelia
    # client_secret hash generated with: authelia crypto hash generate pbkdf2 --password <secret>
    services.authelia.instances.main.settings.identity_providers.oidc.clients = [
      {
        client_id = "immich";
        client_name = "Immich";
        client_secret = "$pbkdf2-sha512$310000$oCkOJgdGAH/cHnDopJbuCQ$eknxkWx3IYQ0Bo.PDN1p4pcmdcrumz94g3eQ8bRtrp/MNsBh9wzFG85HlRuLiLE9D2Tq8afgQ2.HXiONRR4fZw";
        public = false;
        authorization_policy = "one_factor";
        consent_mode = "implicit";
        token_endpoint_auth_method = "client_secret_post";
        redirect_uris = [
          "https://${serviceDomain}/auth/login"
          "https://${serviceDomain}/user-settings"
          "https://immich.${publicDomain}/auth/login"
          "https://immich.${publicDomain}/user-settings"
          "app.immich:///oauth-callback"
        ];
        scopes = [
          "openid"
          "profile"
          "email"
        ];
      }
    ];

    # postgresql backup/restore integration
    clan.core.postgresql.enable = true;
    clan.core.postgresql.databases.immich = {
      create.enable = false; # immich module creates it
      restore.stopOnRestore = [
        "immich-server.service"
        "immich-machine-learning.service"
        "redis-immich.service"
      ];
    };

    # nginx reverse proxy
    nixfiles.nginx.vhosts.immich = {
      inherit (config.services.immich) port;
      extraConfig = ''
        client_max_body_size 50000M;
        proxy_read_timeout   600s;
        proxy_send_timeout   600s;
        send_timeout         600s;
      '';
    };

    services.immich = {
      enable = true;
      host = "127.0.0.1";
      port = 2283;
      mediaLocation = "/tank/apps/immich";
      secretsFile = config.clan.core.vars.generators.immich.files."db-password.env".path;

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
        enable = false; # FIXME
        environment = {
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
          externalDomain = "https://${serviceDomain}";
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
          issuerUrl = "https://auth.${publicDomain}/.well-known/openid-configuration";
          scope = "openid profile email";
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

    environment.systemPackages = with pkgs; [
      immich-go
    ];
  };
}

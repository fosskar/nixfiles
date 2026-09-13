{
  flake.modules.nixos.microbin =
    {
      flake-self,
      config,
      lib,
      pkgs,
      ...
    }:
    let
      serviceName = "bin";
      localHost = "${serviceName}.${flake-self.domains.local}";
      listenAddress = "127.0.0.1";
      listenPort = 8083;
      listenUrl = "http://${listenAddress}:${toString listenPort}";
      dataDir = "/var/lib/microbin";
    in
    {
      clan.core.vars.generators.microbin = {
        files."env".restartUnits = [ "microbin.service" ];
        runtimeInputs = [ pkgs.pwgen ];
        script = ''
          {
            echo "MICROBIN_ADMIN_USERNAME=admin"
            echo "MICROBIN_ADMIN_PASSWORD=$(pwgen -s 48 1)"
          } > "$out/env"
        '';
      };

      services.microbin = {
        enable = true;
        inherit dataDir;
        passwordFile = config.clan.core.vars.generators.microbin.files."env".path;
        settings = {
          MICROBIN_BIND = listenAddress;
          MICROBIN_PORT = listenPort;
          MICROBIN_PUBLIC_PATH = "https://${localHost}";
          MICROBIN_TITLE = "MicroBin";
          MICROBIN_NO_LISTING = true;
          MICROBIN_PRIVATE = true;
          MICROBIN_DEFAULT_PRIVACY = "unlisted";
          MICROBIN_HIGHLIGHTSYNTAX = true;
          MICROBIN_ENABLE_BURN_AFTER = true;
          MICROBIN_ENCRYPTION_SERVER_SIDE = true;
          MICROBIN_ENCRYPTION_CLIENT_SIDE = true;
          MICROBIN_QR = true;
          MICROBIN_HASH_IDS = true;
          MICROBIN_DEFAULT_EXPIRY = "1week";
          MICROBIN_MAX_EXPIRY = "1year";
          MICROBIN_MAX_FILE_SIZE_UNENCRYPTED_MB = 512;
          MICROBIN_MAX_FILE_SIZE_ENCRYPTED_MB = 128;
          MICROBIN_DISABLE_UPDATE_CHECKING = true;
        };
      };

      # consistent sqlite snapshot into /var/backup for the borg backup;
      # attachments are plain files and are backed up from the live dir
      clan.core.state.microbin = {
        folders = [
          "/var/backup/microbin"
          "${dataDir}/microbin_data/attachments"
        ];
        preBackupScript = ''
          export PATH=${
            lib.makeBinPath [
              pkgs.sqlite
              pkgs.coreutils
            ]
          }
          mkdir -p /var/backup/microbin
          sqlite3 ${dataDir}/microbin_data/database.sqlite ".backup '/var/backup/microbin/database.sqlite'"
        '';
      };

      services.homepage-dashboard.services = [
        {
          "tools" = [
            {
              "MicroBin" = {
                href = "https://${localHost}";
                icon = "microbin.png";
                siteMonitor = listenUrl;
              };
            }
          ];
        }
      ];

      services.gatus.settings.endpoints = [
        {
          name = "MicroBin";
          # backend check on purpose: the edge is forward-auth, authelia answers 302 without reaching the service
          url = listenUrl;
          enabled = true;
          alerts = [ { type = "email"; } ];
          interval = "5m";
          conditions = [ "[STATUS] == 200" ];
        }
      ];

      # viewing a paste by link is open; everything else (create form, /upload,
      # /list, /edit, /remove, /admin) goes through authelia. route list from
      # microbin 2.1.4 src/endpoints and src/main.rs
      services.caddy.virtualHosts.${localHost}.extraConfig = ''
        @protected not path /p/* /u/* /upload/* /raw/* /file/* /url/* /qr/* /archive/* /auth/* /auth_file/* /auth_raw/* /secure_file/* /edit_private/* /submit_edit_private/* /auth_edit_private/* /auth_remove_private/* /static/*
        ${lib.optionalString (config.services.authelia.instances.main.enable or false) ''
          forward_auth @protected 127.0.0.1:9091 {
            uri /api/authz/forward-auth
            copy_headers Remote-User Remote-Groups Remote-Name Remote-Email
          }
        ''}
        reverse_proxy ${listenUrl}
      '';
    };
}

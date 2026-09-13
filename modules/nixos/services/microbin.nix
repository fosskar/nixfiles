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
        files = {
          "env".restartUnits = [ "microbin.service" ];
          "uploader-password" = { };
        };
        runtimeInputs = [ pkgs.pwgen ];
        script = ''
          UPLOADER_PW=$(pwgen -s 20 1)
          echo -n "$UPLOADER_PW" > "$out/uploader-password"
          {
            echo "MICROBIN_ADMIN_USERNAME=admin"
            echo "MICROBIN_ADMIN_PASSWORD=$(pwgen -s 48 1)"
            echo "MICROBIN_UPLOADER_PASSWORD=$UPLOADER_PW"
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
          # viewing shared links is open; creating pastas needs MICROBIN_UPLOADER_PASSWORD
          MICROBIN_READONLY = true;
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
          url = "https://${localHost}";
          enabled = true;
          alerts = [ { type = "email"; } ];
          interval = "5m";
          conditions = [ "[STATUS] == 200" ];
        }
      ];

      services.caddy.virtualHosts.${localHost}.extraConfig = ''
        reverse_proxy ${listenUrl}
      '';
    };
}

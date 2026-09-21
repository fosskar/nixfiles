{
  flake.modules.nixos.microbin =
    {
      flake-self,
      config,
      pkgs,
      ...
    }:
    let
      serviceName = "bin";
      localHost = "${serviceName}.${flake-self.domains.local}";
      publicHost = "${serviceName}.${flake-self.domains.public}";
      # exposed publicly through netbird-proxy (target nixbox:8083 in the netbird UI),
      # so the bind must be mesh-reachable; the LAN firewall stays closed
      listenAddress = "0.0.0.0";
      listenPort = 8083;
      listenUrl = "http://127.0.0.1:${toString listenPort}";
      dataDir = "/var/lib/microbin";
    in
    {
      clan.core.vars.generators.microbin = {
        prompts."uploader_password" = {
          description = "password people need to create pastas (viewing links is open)";
          persist = true;
        };
        files."env".restartUnits = [ "microbin.service" ];
        runtimeInputs = [ pkgs.pwgen ];
        script = ''
          {
            echo "MICROBIN_ADMIN_USERNAME=admin"
            echo "MICROBIN_ADMIN_PASSWORD=$(pwgen -s 48 1)"
            echo "MICROBIN_UPLOADER_PASSWORD=$(cat "$prompts/uploader_password")"
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
          MICROBIN_PUBLIC_PATH = "https://${publicHost}";
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

      services.homepage-dashboard.services = [
        {
          "tools" = [
            {
              "MicroBin" = {
                href = "https://${localHost}";
                icon = "sh-microbin";
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
          alerts = [ { type = "matrix"; } ];
          interval = "5m";
          conditions = [ "[STATUS] == 200" ];
        }
      ];

      services.caddy.virtualHosts.${localHost}.extraConfig = ''
        reverse_proxy ${listenUrl}
      '';
    };
}

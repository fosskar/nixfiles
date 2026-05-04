# garage distributed storage with web UI
# secrets (rpc_secret, admin_token) managed by clan garage service
{
  flake.modules.nixos.garage =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      serviceName = "s3";
      localHost = "${serviceName}.${config.domains.local}";
      listenAddress = "127.0.0.1";
      listenPort = 3909;
      adminPort = 3903;
      s3Port = 3900;
      listenUrl = "http://${listenAddress}:${toString listenPort}";
      zone = "dc1";
      autheliaEnabled = config.services.authelia.instances.main.enable or false;
      dataEntry = builtins.head config.services.garage.settings.data_dir;
    in
    {
      config = {
        services.garage.package = pkgs.garage_2;

        services.garage.settings = {
          metadata_dir = "/var/lib/garage/meta";
          data_dir = lib.mkDefault [
            {
              path = "/var/lib/garage/data";
              capacity = "100G";
            }
          ];
          replication_factor = 1;
          rpc_bind_addr = "[::]:3901";
          s3_api = {
            s3_region = lib.mkDefault config.networking.hostName;
            api_bind_addr = "[::]:${toString s3Port}";
          };
          admin = {
            api_bind_addr = "[::]:${toString adminPort}";
          };
        };

        services.homepage-dashboard.serviceGroups."Infrastructure" =
          lib.mkIf config.services.homepage-dashboard.enable
            [
              {
                "Garage" = {
                  href = "https://${localHost}";
                  icon = "garage.svg";
                  siteMonitor = listenUrl;
                };
              }
            ];

        services.gatus.settings.endpoints = lib.mkIf config.services.gatus.enable [
          {
            name = "Garage";
            url = listenUrl;
            group = "Infrastructure";
            enabled = true;
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
            alerts = [ { type = "ntfy"; } ];
          }
        ];

        services.caddy.virtualHosts.${localHost}.extraConfig = ''
          import authelia
          reverse_proxy ${listenUrl}
        '';

        services.authelia.instances.main.settings.access_control.rules = lib.mkIf autheliaEnabled (
          lib.mkBefore [
            {
              domain = [ localHost ];
              subject = [ "group:admin" ];
              policy = "one_factor";
            }
            {
              domain = [ localHost ];
              policy = "deny";
            }
          ]
        );

        systemd.tmpfiles.rules = [
          "d ${dataEntry.path} 0770 - - -"
        ];

        systemd.services.garage-layout-init = {
          description = "garage cluster layout init";
          after = [ "garage.service" ];
          requires = [ "garage.service" ];
          wantedBy = [ "multi-user.target" ];
          unitConfig.ConditionPathExists = "!/var/lib/garage/meta/.layout-initialized";
          path = [ pkgs.garage_2 ];
          environment = {
            GARAGE_RPC_SECRET_FILE = "/run/credentials/garage-layout-init.service/rpc_secret";
            GARAGE_ADMIN_TOKEN_FILE = "/run/credentials/garage-layout-init.service/admin_token";
          };
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            LoadCredential = [
              "rpc_secret:/run/credentials/garage.service/rpc_secret_path"
              "admin_token:/run/credentials/garage.service/admin_token_path"
            ];
          };
          script = ''
            for i in $(seq 1 30); do
              garage status >/dev/null 2>&1 && break
              sleep 2
            done

            node_id=$(garage node id 2>/dev/null | head -1 | cut -c1-16)
            if [ -z "$node_id" ]; then
              echo "failed to get node id" >&2
              exit 1
            fi

            if garage layout show 2>/dev/null | grep -q "$node_id"; then
              touch /var/lib/garage/meta/.layout-initialized
              exit 0
            fi

            garage layout assign -z ${lib.escapeShellArg zone} -c ${lib.escapeShellArg dataEntry.capacity} "$node_id"

            version=$(garage layout show 2>/dev/null | grep -oP 'apply --version \K[0-9]+')
            garage layout apply --version "$version"

            touch /var/lib/garage/meta/.layout-initialized
          '';
        };

        systemd.services.garage-webui = {
          description = "garage web ui";
          after = [ "garage.service" ];
          wantedBy = [ "multi-user.target" ];
          environment = {
            CONFIG_PATH = "/etc/garage.toml";
            API_BASE_URL = "http://localhost:${toString adminPort}";
            S3_ENDPOINT_URL = "http://localhost:${toString s3Port}";
            S3_REGION = config.services.garage.settings.s3_api.s3_region;
            PORT = toString listenPort;
          };
          serviceConfig = {
            Restart = "always";
            DynamicUser = true;
            LoadCredential = [
              "admin_token:/run/credentials/garage.service/admin_token_path"
            ];
          };
          script = ''
            export API_ADMIN_KEY=$(cat "$CREDENTIALS_DIRECTORY/admin_token")
            exec ${pkgs.garage-webui}/bin/garage-webui
          '';
        };
      };
    };
}

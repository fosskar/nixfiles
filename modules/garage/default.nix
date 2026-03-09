# garage distributed storage with web UI
# secrets (rpc_secret, admin_token) managed by clan garage service
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixfiles.garage;
  acmeDomain = config.nixfiles.caddy.domain;
  serviceDomain = "s3.${acmeDomain}";
  webuiPort = 3909;
  adminPort = 3903;
  s3Port = 3900;
  internalUrl = "http://127.0.0.1:${toString webuiPort}";
in
{
  # --- options ---

  options.nixfiles.garage = {
    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "path to garage data directory";
    };

    capacity = lib.mkOption {
      type = lib.types.str;
      default = "100G";
      description = "storage capacity for this node";
    };

    s3Region = lib.mkOption {
      type = lib.types.str;
      default = config.networking.hostName;
      description = "S3 region name (defaults to hostname)";
    };

    zone = lib.mkOption {
      type = lib.types.str;
      default = "dc1";
      description = "zone name for layout assignment";
    };
  };

  # --- service ---

  config = {
    services.garage.package = pkgs.garage_2;

    services.garage.settings = {
      metadata_dir = "/var/lib/garage/meta";
      data_dir = [
        {
          path = cfg.dataDir;
          inherit (cfg) capacity;
        }
      ];
      replication_factor = 1;
      rpc_bind_addr = "[::]:3901";
      s3_api = {
        s3_region = cfg.s3Region;
        api_bind_addr = "[::]:${toString s3Port}";
      };
      admin = {
        api_bind_addr = "[::]:${toString adminPort}";
      };
    };

    # --- homepage ---

    nixfiles.homepage.entries = lib.mkIf config.services.homepage-dashboard.enable [
      {
        name = "Garage";
        category = "Infrastructure";
        icon = "garage.svg";
        href = "https://${serviceDomain}";
        siteMonitor = internalUrl;
      }
    ];

    # --- gatus ---

    nixfiles.gatus.endpoints = lib.mkIf config.nixfiles.gatus.enable [
      {
        name = "Garage";
        url = internalUrl;
        group = "Infrastructure";
      }
    ];

    # --- caddy ---

    nixfiles.caddy.vhosts.s3 = {
      port = webuiPort;
      proxy-auth = true;
    };

    # --- systemd ---

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0770 - - -"
    ];

    # auto-assign node to cluster layout on first boot
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
        # wait for garage to be ready
        for i in $(seq 1 30); do
          garage status >/dev/null 2>&1 && break
          sleep 2
        done

        node_id=$(garage node id 2>/dev/null | head -1 | cut -c1-16)
        if [ -z "$node_id" ]; then
          echo "failed to get node id" >&2
          exit 1
        fi

        # check if already assigned
        if garage layout show 2>/dev/null | grep -q "$node_id"; then
          touch /var/lib/garage/meta/.layout-initialized
          exit 0
        fi

        garage layout assign -z ${lib.escapeShellArg cfg.zone} -c ${lib.escapeShellArg cfg.capacity} "$node_id"

        # get next layout version
        version=$(garage layout show 2>/dev/null | grep -oP 'apply --version \K[0-9]+')
        garage layout apply --version "$version"

        touch /var/lib/garage/meta/.layout-initialized
      '';
    };

    # web UI
    systemd.services.garage-webui = {
      description = "garage web ui";
      after = [ "garage.service" ];
      wantedBy = [ "multi-user.target" ];
      environment = {
        CONFIG_PATH = "/etc/garage.toml";
        API_BASE_URL = "http://localhost:${toString adminPort}";
        S3_ENDPOINT_URL = "http://localhost:${toString s3Port}";
        S3_REGION = cfg.s3Region;
        PORT = toString webuiPort;
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
}

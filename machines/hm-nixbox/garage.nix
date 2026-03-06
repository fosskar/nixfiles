{ pkgs, ... }:
{
  systemd.tmpfiles.rules = [
    "d /tank/apps/garage 0770 - - -"
  ];

  services.garage.package = pkgs.garage_2;

  services.garage.settings = {
    metadata_dir = "/var/lib/garage/meta";
    data_dir = [
      {
        path = "/tank/apps/garage";
        capacity = "100G";
      }
    ];
    replication_factor = 1;
    rpc_bind_addr = "[::]:3901";
    s3_api = {
      s3_region = "hm-nixbox";
      api_bind_addr = "[::]:3900";
    };
    admin = {
      api_bind_addr = "[::]:3903";
    };
  };

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
      if garage layout show 2>/dev/null | grep -q "$node_id.*100.0 GB"; then
        touch /var/lib/garage/meta/.layout-initialized
        exit 0
      fi

      garage layout assign -z dc1 -c 100G "$node_id"

      # get next layout version
      version=$(garage layout show 2>/dev/null | grep -oP 'apply --version \K[0-9]+')
      garage layout apply --version "$version"

      touch /var/lib/garage/meta/.layout-initialized
    '';
  };

  # garage web ui
  systemd.services.garage-webui = {
    description = "garage web ui";
    after = [ "garage.service" ];
    wantedBy = [ "multi-user.target" ];
    environment = {
      CONFIG_PATH = "/etc/garage.toml";
      API_BASE_URL = "http://localhost:3903";
      S3_ENDPOINT_URL = "http://localhost:3900";
      S3_REGION = "hm-nixbox";
      PORT = "3909";
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

  nixfiles.nginx.vhosts.s3 = {
    port = 3909;
    proxy-auth = true;
  };
}

{ self, ... }:
{ lib, ... }:
let
  inherit (lib) attrNames flip;

  # shared sign-key generator (server signs, clients trust pubkey).
  varsForInstance = instanceName: pkgs: {
    clan.core.vars.generators."niks3" = {
      share = true;
      files.sign-key.secret = true;
      files.sign-key.deploy = false;
      files.pub-key.secret = false;
      script = ''
        ${pkgs.nix}/bin/nix-store --generate-binary-cache-key ${instanceName}-1 \
          $out/sign-key \
          $out/pub-key
      '';
    };
  };
in
{
  _class = "clan.service";
  manifest.name = "niks3";
  manifest.description = "self-hosted nix binary cache via niks3 with bundled garage s3 backend";
  manifest.readme = "niks3 server with bundled garage s3 backend; server role hosts cache, client role wires substituter";
  manifest.categories = [ "Nix Tools" ];

  roles.server = {
    description = "niks3 server with bundled garage s3 backend";

    perInstance =
      { instanceName, ... }:
      {
        nixosModule =
          {
            config,
            pkgs,
            lib,
            ...
          }:
          let
            niks3Pkgs = self.inputs.niks3.packages.${pkgs.stdenv.hostPlatform.system};
            bucketName = "${config.networking.hostName}.${config.clan.core.settings.domain}";
            niks3Port = 5751;
            garageS3Port = 3900;
            garageRpcPort = 3901;
            garageWebPort = 3902;
            garageAdminPort = 3903;
            varsGarage = config.clan.core.vars.generators."niks3-garage";
            varsKeys = config.clan.core.vars.generators."niks3-private";
            stateDir = "/var/lib/niks3";
            s3AccessFile = "${stateDir}/s3-access";
            s3SecretFile = "${stateDir}/s3-secret";
          in
          {
            imports = [
              (varsForInstance instanceName pkgs)
              self.inputs.niks3.nixosModules.niks3
              self.inputs.niks3.nixosModules.niks3-auto-upload
            ];

            # private copy of sign-key (deployed to host, used by niks3 server).
            clan.core.vars.generators."niks3-private" = {
              dependencies = [ "niks3" ];
              files.sign-key.secret = true;
              files.sign-key.owner = "niks3";
              files.sign-key.group = "niks3";
              script = "cp $in/niks3/sign-key $out/sign-key";
            };

            # per-machine garage credentials + niks3 api token.
            clan.core.vars.generators."niks3-garage" = {
              files.rpc_secret.secret = true;
              files.admin_token.secret = true;
              files.metrics_token.secret = true;
              files.api-token.secret = true;
              files.api-token.owner = "niks3";
              files.api-token.group = "niks3";
              runtimeInputs = [ pkgs.openssl ];
              script = ''
                openssl rand -hex 32 > "$out/rpc_secret"
                openssl rand -base64 32 > "$out/admin_token"
                openssl rand -base64 32 > "$out/metrics_token"
                openssl rand -hex 32 > "$out/api-token"
              '';
            };

            # ----- garage -----
            services.garage = {
              enable = true;
              package = pkgs.garage_2;
              settings = {
                metadata_dir = "/var/lib/garage/meta";
                data_dir = [
                  {
                    path = "/var/lib/garage/data";
                    capacity = "200G";
                  }
                ];
                replication_factor = 1;
                rpc_bind_addr = "[::]:${toString garageRpcPort}";
                s3_api = {
                  s3_region = config.networking.hostName;
                  api_bind_addr = "127.0.0.1:${toString garageS3Port}";
                };
                s3_web = {
                  bind_addr = "[::]:${toString garageWebPort}";
                  root_domain = "";
                  index = "index.html";
                };
                admin = {
                  api_bind_addr = "127.0.0.1:${toString garageAdminPort}";
                };
              };
            };

            systemd.services.garage.serviceConfig = {
              LoadCredential = [
                "rpc_secret_path:${varsGarage.files.rpc_secret.path}"
                "admin_token_path:${varsGarage.files.admin_token.path}"
                "metrics_token_path:${varsGarage.files.metrics_token.path}"
              ];
              Environment = [
                "GARAGE_ALLOW_WORLD_READABLE_SECRETS=true"
                "GARAGE_RPC_SECRET_FILE=%d/rpc_secret_path"
                "GARAGE_ADMIN_TOKEN_FILE=%d/admin_token_path"
                "GARAGE_METRICS_TOKEN_FILE=%d/metrics_token_path"
              ];
            };

            systemd.tmpfiles.rules = [
              "d /var/lib/garage/data 0770 - - -"
              "d ${stateDir} 0750 niks3 niks3 -"
            ];

            # one-shot: assign + apply garage cluster layout.
            systemd.services.niks3-garage-layout-init = {
              description = "garage cluster layout init for niks3";
              after = [ "garage.service" ];
              requires = [ "garage.service" ];
              wantedBy = [ "multi-user.target" ];
              unitConfig.ConditionPathExists = "!/var/lib/garage/meta/.layout-initialized";
              path = [ pkgs.garage_2 ];
              environment = {
                GARAGE_RPC_SECRET_FILE = "/run/credentials/niks3-garage-layout-init.service/rpc_secret";
                GARAGE_ADMIN_TOKEN_FILE = "/run/credentials/niks3-garage-layout-init.service/admin_token";
              };
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
                LoadCredential = [
                  "rpc_secret:${varsGarage.files.rpc_secret.path}"
                  "admin_token:${varsGarage.files.admin_token.path}"
                ];
              };
              script = ''
                for i in $(seq 1 30); do
                  garage status >/dev/null 2>&1 && break
                  sleep 2
                done

                node_id=$(garage node id 2>/dev/null | head -1 | cut -c1-16)
                if [ -z "$node_id" ]; then
                  echo "failed to get garage node id" >&2
                  exit 1
                fi

                if garage layout show 2>/dev/null | grep -q "$node_id"; then
                  touch /var/lib/garage/meta/.layout-initialized
                  exit 0
                fi

                garage layout assign -z dc1 -c 200G "$node_id"
                version=$(garage layout show 2>/dev/null | grep -oP 'apply --version \K[0-9]+')
                garage layout apply --version "$version"

                touch /var/lib/garage/meta/.layout-initialized
              '';
            };

            # one-shot: create bucket, allow website, mint s3 key for niks3.
            systemd.services.niks3-bucket-init = {
              description = "niks3 garage bucket + s3 key bootstrap";
              after = [ "niks3-garage-layout-init.service" ];
              requires = [ "niks3-garage-layout-init.service" ];
              wantedBy = [ "multi-user.target" ];
              unitConfig.ConditionPathExists = "!${stateDir}/.bucket-initialized";
              path = [
                pkgs.garage_2
                pkgs.coreutils
                pkgs.gnugrep
              ];
              environment = {
                GARAGE_RPC_SECRET_FILE = "/run/credentials/niks3-bucket-init.service/rpc_secret";
                GARAGE_ADMIN_TOKEN_FILE = "/run/credentials/niks3-bucket-init.service/admin_token";
              };
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
                LoadCredential = [
                  "rpc_secret:${varsGarage.files.rpc_secret.path}"
                  "admin_token:${varsGarage.files.admin_token.path}"
                ];
              };
              script = ''
                set -euo pipefail

                # create bucket if missing.
                if ! garage bucket info ${bucketName} >/dev/null 2>&1; then
                  garage bucket create ${bucketName}
                fi

                # enable website mode -> anonymous reads on web endpoint.
                garage bucket website --allow ${bucketName}

                # mint key if missing.
                if ! garage key info niks3-key >/dev/null 2>&1; then
                  garage key create niks3-key
                fi

                key_info=$(garage key info --show-secret niks3-key)
                key_id=$(echo "$key_info" | grep -oP 'Key ID:\s*\K\S+')
                key_secret=$(echo "$key_info" | grep -oP 'Secret key:\s*\K\S+')

                # grant key read+write on bucket.
                garage bucket allow --read --write --key niks3-key ${bucketName}

                # write creds for niks3 server.
                install -m 0640 -o niks3 -g niks3 /dev/null ${s3AccessFile}
                install -m 0640 -o niks3 -g niks3 /dev/null ${s3SecretFile}
                printf '%s' "$key_id" > ${s3AccessFile}
                printf '%s' "$key_secret" > ${s3SecretFile}

                touch ${stateDir}/.bucket-initialized
              '';
            };

            # ----- niks3 server -----
            services.niks3 = {
              enable = true;
              httpAddr = "0.0.0.0:${toString niks3Port}";

              database.createLocally = false;
              database.connectionString = "postgres:///niks3?host=/run/postgresql";

              s3 = {
                endpoint = "127.0.0.1:${toString garageS3Port}";
                bucket = bucketName;
                region = config.networking.hostName;
                useSSL = false;
                accessKeyFile = s3AccessFile;
                secretKeyFile = s3SecretFile;
              };

              apiTokenFile = varsGarage.files.api-token.path;
              signKeyFiles = [ varsKeys.files.sign-key.path ];

              gc.enable = true;
              gc.olderThan = "720h";
            };

            # niks3 server depends on bucket bootstrap + postgres.
            systemd.services.niks3 = {
              after = [
                "niks3-bucket-init.service"
                "postgresql.service"
              ];
              requires = [ "niks3-bucket-init.service" ];
            };

            # postgres via clan-core wrapper (consistent with paperless/immich/etc).
            clan.core.postgresql.enable = true;
            clan.core.postgresql.databases.niks3 = {
              create.enable = true;
              create.options.OWNER = "niks3";
              restore.stopOnRestore = [ "niks3.service" ];
            };
            clan.core.postgresql.users.niks3 = { };

            # ----- system-wide post-build-hook upload -----
            services.niks3-auto-upload = {
              enable = true;
              serverUrl = "http://127.0.0.1:${toString niks3Port}";
              authTokenFile = varsGarage.files.api-token.path;
            };

            # ----- buildbot-nix postBuildStep upload -----
            services.buildbot-nix.master.niks3 = lib.mkIf config.services.buildbot-nix.master.enable {
              enable = true;
              serverUrl = "http://127.0.0.1:${toString niks3Port}";
              authTokenFile = varsGarage.files.api-token.path;
              package = niks3Pkgs.niks3;
            };

            # firewall: niks3 server + garage web endpoint (anonymous reads).
            networking.firewall.allowedTCPPorts = [
              niks3Port
              garageWebPort
            ];
          };
      };
  };

  roles.client = {
    description = "machine using niks3 cache as substituter";

    perInstance =
      {
        instanceName,
        roles,
        ...
      }:
      {
        nixosModule =
          { config, pkgs, ... }:
          {
            imports = [ (varsForInstance instanceName pkgs) ];

            nix.settings.substituters =
              let
                inherit (config.clan.core.settings) domain;
                dotDomain = if domain != null then ".${domain}" else "";
              in
              flip map (attrNames roles.server.machines) (
                machineName: "http://${machineName}${dotDomain}:3902?priority=20"
              );

            nix.settings.trusted-public-keys = [
              config.clan.core.vars.generators."niks3".files.pub-key.value
            ];
          };
      };
  };
}

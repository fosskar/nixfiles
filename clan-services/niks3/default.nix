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
  manifest.readme = builtins.readFile ./README.md;
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
            # friendly bucket name; webHost is an extra global alias garage uses
            # to route the cache website (clients fetch http://<webHost>:3902).
            bucketName = "niks3-cache";
            webHost = "${config.networking.hostName}.${config.clan.core.settings.domain}";
            niks3Port = 5751;
            garageS3Port = 3900;
            garageWebPort = 3902;
            varsGarage = config.clan.core.vars.generators."niks3-garage";
            varsKeys = config.clan.core.vars.generators."niks3-private";
            # garage cluster secrets owned by the garage clan-service; this
            # machine must also be a garage `peer`.
            garageShared = config.clan.core.vars.generators."garage-shared";
            garageTokens = config.clan.core.vars.generators."garage";
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

            clan.core.vars.generators."niks3-garage" = {
              files.api-token.secret = true;
              files.api-token.owner = "niks3";
              files.api-token.group = "niks3";
              runtimeInputs = [ pkgs.openssl ];
              script = ''
                openssl rand -hex 32 > "$out/api-token"
              '';
            };

            systemd.tmpfiles.rules = [
              "d ${stateDir} 0750 niks3 niks3 -"
            ];

            # one-shot: create bucket, allow website, mint s3 key for niks3.
            systemd.services.niks3-bucket-init = {
              description = "niks3 garage bucket + s3 key bootstrap";
              after = [ "garage.service" ];
              requires = [ "garage.service" ];
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
                  "rpc_secret:${garageShared.files.rpc_secret.path}"
                  "admin_token:${garageTokens.files.admin_token.path}"
                ];
              };
              script = ''
                set -euo pipefail

                # wait for the local garage node and a usable cluster layout.
                for i in $(seq 1 60); do
                  garage layout show 2>/dev/null | grep -q 'Current cluster layout version' && break
                  sleep 2
                done

                # create bucket if missing.
                if ! garage bucket info ${bucketName} >/dev/null 2>&1; then
                  garage bucket create ${bucketName}
                fi

                # website Host alias (clients read at http://${webHost}:3902).
                garage bucket alias ${bucketName} ${webHost} 2>/dev/null || true

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
              package = niks3Pkgs.niks3-hook;
              serverUrl = "http://127.0.0.1:${toString niks3Port}";
              authTokenFile = varsGarage.files.api-token.path;
            };

            # ----- nixbot niks3 upload -----
            # disabled: nix post-build-hook already uploads local nixbot builds.
            services.nixbot.niks3 = lib.mkIf config.services.nixbot.enable {
              enable = false;
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
          {
            config,
            pkgs,
            lib,
            ...
          }:
          {
            imports = [ (varsForInstance instanceName pkgs) ];

            nix.settings = lib.mkIf (!(builtins.hasAttr config.networking.hostName roles.server.machines)) {
              substituters =
                let
                  inherit (config.clan.core.settings) domain;
                  dotDomain = if domain != null then ".${domain}" else "";
                in
                flip map (attrNames roles.server.machines) (
                  machineName: "http://${machineName}${dotDomain}:3902?priority=1"
                );

              trusted-public-keys = [
                config.clan.core.vars.generators."niks3".files.pub-key.value
              ];
            };
          };
      };
  };
}

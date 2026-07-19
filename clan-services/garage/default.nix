# garage S3 cluster: multi-node clustering with replication + layout bootstrap,
# on top of the single-node clan-core/garage. optional `ui` role for garage-ui.
{ self, ... }:
_:
let
  rpcPort = 3901;
  s3Port = 3900;
  webPort = 3902;
  adminPort = 3903;
in
{
  _class = "clan.service";
  manifest.name = "garage";
  manifest.description = "S3-compatible object store, clustered with replication and an optional web ui";
  manifest.categories = [ "System" ];
  manifest.readme = builtins.readFile ./README.md;

  roles.node = {
    description = "garage storage node; joins the cluster and stores data";

    interface =
      { lib, ... }:
      {
        options = {
          zone = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "garage layout zone; defaults to the machine name. use a distinct zone per physical node so replicas spread across nodes.";
          };
          capacity = lib.mkOption {
            type = lib.types.str;
            description = "advertised storage capacity for this node, e.g. \"250G\". per-node; nodes may differ.";
          };
          dataPath = lib.mkOption {
            type = lib.types.str;
            default = "/var/lib/garage/data";
            description = "filesystem path for this node's garage data blocks.";
          };
          rpcAddr = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = ''
              address other nodes use to reach this node's rpc port. defaults to
              the clan yggdrasil name `<machine>.s` (resolved via /etc/hosts on
              every machine), so it normally needs no value. override with a LAN
              IP if you prefer raw-LAN rpc over the overlay.
            '';
          };
          ui.enable = lib.mkEnableOption "the garage-ui web interface on this node";
          buckets = lib.mkOption {
            type = lib.types.attrsOf (
              lib.types.submodule {
                options = {
                  website = lib.mkEnableOption "anonymous reads for this bucket via the s3 web endpoint (:3902)";
                  aliases = lib.mkOption {
                    type = lib.types.listOf lib.types.str;
                    default = [ ];
                    description = "extra global aliases, e.g. Host names the web endpoint routes to this bucket.";
                  };
                };
              }
            );
            default = { };
            description = ''
              cluster-wide s3 buckets to create automatically, each with its own
              pre-generated read+write key in the shared `garage-buckets` vars
              generator. set at role level so every node agrees on the set.
            '';
          };
        };
      };

    perInstance =
      { settings, roles, ... }:
      {
        nixosModule =
          {
            config,
            pkgs,
            lib,
            ...
          }:
          let
            nodeNames = lib.attrNames roles.node.machines;
            bootstrapNode = lib.head (lib.sort (a: b: a < b) nodeNames);
            # garage requires replication_factor <= node count.
            replicationFactor = lib.min 3 (lib.length nodeNames);

            inherit ((nodeSettings bootstrapNode)) buckets;
            bucketNames = lib.attrNames buckets;

            nodeKeyGen = config.clan.core.vars.generators.garage-node;
            nodeId = name: lib.removeSuffix "\n" nodeKeyGen.files."node_id_${name}".value;
            nodeIdShort = name: builtins.substring 0 16 (nodeId name);

            nodeSettings = name: roles.node.machines.${name}.settings;
            zoneOf =
              name:
              let
                z = (nodeSettings name).zone;
              in
              if z != null then z else name;
            rpcAddrOf =
              name:
              let
                s = (nodeSettings name).rpcAddr;
              in
              if s != null then s else "${name}.s";
            bootstrapPeers = map (name: "${nodeId name}@${rpcAddrOf name}:${toString rpcPort}") nodeNames;

            metadataDir = config.services.garage.settings.metadata_dir;
            hostName = config.networking.hostName;

            # runs as root (`+` prefix) after the dynamic user is allocated:
            # boot-time tmpfiles can't resolve the DynamicUser `garage`.
            placeNodeKey = pkgs.writeShellScript "garage-place-node-key" ''
              set -euo pipefail
              install -d -m 0700 -o garage -g garage ${metadataDir} ${settings.dataPath}
              install -m 0600 -o garage -g garage \
                ${nodeKeyGen.files."node_key_${hostName}".path} ${metadataDir}/node_key
              install -m 0644 -o garage -g garage \
                ${nodeKeyGen.files."node_key_${hostName}_pub".path} ${metadataDir}/node_key.pub
            '';

            assignCmds = lib.concatMapStringsSep "\n" (
              name:
              "garage layout assign -z ${lib.escapeShellArg (zoneOf name)} "
              + "-c ${lib.escapeShellArg (nodeSettings name).capacity} ${nodeIdShort name}"
            ) nodeNames;

            # `garage status` lists previously-seen but unreachable peers under
            # "FAILED NODES"; metadata writes need full RF quorum, so only the
            # healthy section (everything before that header) counts.
            waitForHealthyPeers = lib.concatMapStringsSep "\n" (name: ''
              for i in $(seq 1 60); do
                garage status 2>/dev/null | sed '/FAILED NODES/q' | grep -q ${nodeIdShort name} && break
                sleep 2
              done
            '') nodeNames;
          in
          {
            imports = [ self.modules.nixos.garageUi ];

            services.garageUi = {
              enable = settings.ui.enable;
              adminTokenFile = config.clan.core.vars.generators.garage.files.admin_token.path;
            };

            services.garage = {
              enable = true;
              package = pkgs.garage_2;
              settings = {
                metadata_dir = "/var/lib/garage/meta";
                data_dir = lib.mkDefault [
                  {
                    path = settings.dataPath;
                    inherit (settings) capacity;
                  }
                ];
                replication_factor = replicationFactor;
                rpc_bind_addr = "[::]:${toString rpcPort}";
                rpc_public_addr = "${rpcAddrOf hostName}:${toString rpcPort}";
                bootstrap_peers = bootstrapPeers;
                s3_api = {
                  s3_region = lib.mkDefault config.networking.hostName;
                  api_bind_addr = "[::]:${toString s3Port}";
                };
                s3_web = {
                  bind_addr = "[::]:${toString webPort}";
                  root_domain = "";
                  index = "index.html";
                };
                admin.api_bind_addr = "127.0.0.1:${toString adminPort}";
              };
            };

            # s3 api open on lan so other machines can use the buckets.
            networking.firewall.allowedTCPPorts = [
              rpcPort
              s3Port
            ];

            systemd.services.garage = {
              # don't start (and don't create data on the wrong fs) unless the
              # dataPath's backing mount is up; no-op when dataPath sits on /.
              unitConfig.RequiresMountsFor = [ settings.dataPath ];
              serviceConfig = {
                ExecStartPre = [ "+${placeNodeKey}" ];
                LoadCredential = [
                  "rpc_secret_path:${config.clan.core.vars.generators.garage-shared.files.rpc_secret.path}"
                  "admin_token_path:${config.clan.core.vars.generators.garage.files.admin_token.path}"
                  "metrics_token_path:${config.clan.core.vars.generators.garage.files.metrics_token.path}"
                ];
                Environment = [
                  "GARAGE_ALLOW_WORLD_READABLE_SECRETS=true"
                  "GARAGE_RPC_SECRET_FILE=%d/rpc_secret_path"
                  "GARAGE_ADMIN_TOKEN_FILE=%d/admin_token_path"
                  "GARAGE_METRICS_TOKEN_FILE=%d/metrics_token_path"
                ];
              };
            };

            # per-node admin/metrics tokens; rpc secret shared cluster-wide.
            clan.core.vars.generators.garage = {
              files.admin_token = { };
              files.metrics_token = { };
              runtimeInputs = [
                pkgs.coreutils
                pkgs.openssl
              ];
              script = ''
                openssl rand -base64 -out "$out"/admin_token 32
                openssl rand -base64 -out "$out"/metrics_token 32
              '';
            };

            clan.core.vars.generators.garage-shared = {
              share = true;
              files.rpc_secret = { };
              runtimeInputs = [
                pkgs.coreutils
                pkgs.openssl
              ];
              script = ''
                openssl rand -hex -out "$out"/rpc_secret 32
              '';
            };

            # pre-seed every peer's node identity (node_key: 64-byte ed25519
            # seed||pub, node_key.pub: 32-byte pub, node_id: hex pub) so
            # bootstrap_peers is static and known at eval time.
            clan.core.vars.generators.garage-node = {
              share = true;
              files = lib.foldl' (
                acc: name:
                acc
                // {
                  "node_key_${name}" = { };
                  "node_key_${name}_pub".secret = false;
                  "node_id_${name}".secret = false;
                }
              ) { } nodeNames;
              runtimeInputs = [ (pkgs.python3.withPackages (ps: [ ps.pynacl ])) ];
              script = ''
                python3 - <<'PY'
                import os
                from nacl.signing import SigningKey
                out = os.environ["out"]
                for p in "${lib.concatStringsSep " " nodeNames}".split():
                    sk = SigningKey.generate()
                    seed = bytes(sk)
                    pub = bytes(sk.verify_key)
                    with open(f"{out}/node_key_{p}", "wb") as f:
                        f.write(seed + pub)
                    with open(f"{out}/node_key_{p}_pub", "wb") as f:
                        f.write(pub)
                    with open(f"{out}/node_id_{p}", "w") as f:
                        f.write(pub.hex())
                PY
              '';
            };

            # back up a consistent lmdb snapshot, not the live meta db.
            clan.core.state.garage = {
              folders = lib.mkForce [ "/var/backup/garage" ];
              preBackupScript = ''
                set -euo pipefail
                export GARAGE_RPC_SECRET_FILE=${config.clan.core.vars.generators.garage-shared.files.rpc_secret.path}
                ${pkgs.garage_2}/bin/garage meta snapshot
                newest=$(ls -dt ${metadataDir}/snapshots/*/ | head -1)
                rm -rf /var/backup/garage
                mkdir -p /var/backup/garage
                cp -a "$newest" /var/backup/garage/meta
                ls -dt ${metadataDir}/snapshots/*/ | tail -n +2 | xargs -r rm -rf
              '';
            };

            # cluster layout bootstrap: runs once, on a single node, after all
            # peers have connected. idempotent via the marker file.
            systemd.services.garage-layout-init = lib.mkIf (hostName == bootstrapNode) {
              description = "garage cluster layout init";
              after = [ "garage.service" ];
              requires = [ "garage.service" ];
              wantedBy = [ "multi-user.target" ];
              unitConfig.ConditionPathExists = "!${metadataDir}/.layout-initialized";
              path = [ pkgs.garage_2 ];
              environment = {
                GARAGE_RPC_SECRET_FILE = "/run/credentials/garage-layout-init.service/rpc_secret";
                GARAGE_ADMIN_TOKEN_FILE = "/run/credentials/garage-layout-init.service/admin_token";
              };
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
                LoadCredential = [
                  "rpc_secret:${config.clan.core.vars.generators.garage-shared.files.rpc_secret.path}"
                  "admin_token:${config.clan.core.vars.generators.garage.files.admin_token.path}"
                ];
              };
              script = ''
                for i in $(seq 1 60); do
                  garage status >/dev/null 2>&1 && break
                  sleep 2
                done

                ${waitForHealthyPeers}

                ${assignCmds}

                version=$(garage layout show 2>/dev/null | grep -oP 'apply --version \K[0-9]+')
                if [ -n "$version" ]; then
                  garage layout apply --version "$version"
                fi

                touch ${metadataDir}/.layout-initialized
              '';
            };

            # per-bucket s3 credentials, pre-generated in garage's native
            # format (GK + 24 hex id, 64-hex secret) so consumers can fetch
            # them via `clan vars get <machine> garage-buckets/...`.
            clan.core.vars.generators.garage-buckets = lib.mkIf (buckets != { }) {
              share = true;
              files = lib.foldl' (
                acc: b:
                acc
                // {
                  "${b}_access_key_id" = { };
                  "${b}_secret_access_key" = { };
                }
              ) { } bucketNames;
              runtimeInputs = [
                pkgs.coreutils
                pkgs.openssl
              ];
              script = lib.concatMapStringsSep "\n" (b: ''
                printf 'GK%s' "$(openssl rand -hex 12)" > "$out"/${b}_access_key_id
                printf '%s' "$(openssl rand -hex 32)" > "$out"/${b}_secret_access_key
              '') bucketNames;
            };

            # declarative buckets: created on the bootstrap node, each with its
            # pre-generated key imported and granted read+write. idempotent, so
            # growing the list just creates the new buckets on next boot.
            systemd.services.garage-buckets-init = lib.mkIf (buckets != { } && hostName == bootstrapNode) {
              description = "garage declarative buckets bootstrap";
              after = [ "garage-layout-init.service" ];
              requires = [ "garage-layout-init.service" ];
              wantedBy = [ "multi-user.target" ];
              path = [
                pkgs.garage_2
                pkgs.coreutils
                pkgs.gnugrep
                pkgs.gnused
              ];
              environment = {
                GARAGE_RPC_SECRET_FILE = "/run/credentials/garage-buckets-init.service/rpc_secret";
                GARAGE_ADMIN_TOKEN_FILE = "/run/credentials/garage-buckets-init.service/admin_token";
              };
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
                LoadCredential = [
                  "rpc_secret:${config.clan.core.vars.generators.garage-shared.files.rpc_secret.path}"
                  "admin_token:${config.clan.core.vars.generators.garage.files.admin_token.path}"
                ]
                ++ lib.concatMap (b: [
                  "${b}_access_key_id:${
                    config.clan.core.vars.generators.garage-buckets.files."${b}_access_key_id".path
                  }"
                  "${b}_secret_access_key:${
                    config.clan.core.vars.generators.garage-buckets.files."${b}_secret_access_key".path
                  }"
                ]) bucketNames;
              };
              script = ''
                set -euo pipefail

                for i in $(seq 1 60); do
                  garage layout show 2>/dev/null | grep -q 'Current cluster layout version' && break
                  sleep 2
                done

                ${waitForHealthyPeers}

                ${lib.concatStringsSep "\n" (
                  lib.mapAttrsToList (b: def: ''
                    if ! garage bucket info ${b} >/dev/null 2>&1; then
                      garage bucket create ${b}
                    fi

                    key_id=$(cat "$CREDENTIALS_DIRECTORY"/${b}_access_key_id)
                    if ! garage key info "$key_id" >/dev/null 2>&1; then
                      garage key import --yes -n ${b} \
                        "$key_id" "$(cat "$CREDENTIALS_DIRECTORY"/${b}_secret_access_key)"
                    fi

                    garage bucket allow --read --write --key "$key_id" ${b}
                    ${lib.optionalString def.website "garage bucket website --allow ${b}"}
                    ${lib.concatMapStringsSep "\n" (a: "garage bucket alias ${b} ${a} 2>/dev/null || true") def.aliases}
                  '') buckets
                )}
              '';
            };
          };
      };
  };

}

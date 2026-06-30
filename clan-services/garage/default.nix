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

            placeNodeKey = pkgs.writeShellScript "garage-place-node-key" ''
              set -euo pipefail
              install -d -m 0700 -o garage -g garage ${metadataDir}
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

            waitForPeers = lib.concatMapStringsSep "\n" (name: ''
              for i in $(seq 1 60); do
                garage status 2>/dev/null | grep -q ${nodeIdShort name} && break
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

            networking.firewall.allowedTCPPorts = [ rpcPort ];

            systemd.tmpfiles.rules = [ "d ${settings.dataPath} 0700 garage garage -" ];

            systemd.services.garage.serviceConfig = {
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

                ${waitForPeers}

                ${assignCmds}

                version=$(garage layout show 2>/dev/null | grep -oP 'apply --version \K[0-9]+')
                if [ -n "$version" ]; then
                  garage layout apply --version "$version"
                fi

                touch ${metadataDir}/.layout-initialized
              '';
            };
          };
      };
  };

}

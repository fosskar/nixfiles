{ config, ... }:
let
  listenPort = 7700;
  writeActions = [
    "search"
    "documents.*"
    "indexes.*"
    "settings.*"
    "tasks.*"
    "stats.*"
  ];
in
{
  # tenants of the shared meilisearch instance. pure metadata; reachable via
  # self/flake-self, because a tenant on another host cannot read the config
  # of the host that runs meilisearch
  flake.meilisearch = {
    url = "https://meilisearch.${config.flake.domains.local}";

    # one api key per tenant, limited to the tenant's indexes. the uid is
    # arbitrary but fixed: meilisearch derives the key from it
    tenants = {
      silo = {
        uid = "1c0dad77-d863-45b3-b1cf-23af79aa45d3";
        indexes = [ "silo_*" ];
        actions = writeActions;
      };
      radicle-search = {
        uid = "21d5efb6-07bf-4ce7-b0d3-44f01ed84714";
        indexes = [ "radicle_*" ];
        actions = writeActions;
      };
      # radicle-httpd is public and only queries
      radicle-httpd = {
        uid = "148e4aab-a98f-42b3-b505-cf69bfd0d834";
        indexes = [ "radicle_*" ];
        actions = [ "search" ];
      };
    };

    # the master key stays in the vars store (deploy = false), so no machine
    # can decrypt it; the meilisearch host and every tenant derive from it.
    # clan requires identical definitions on all definers
    masterGenerator = pkgs: {
      share = true;
      files.key.deploy = false;
      runtimeInputs = [ pkgs.openssl ];
      script = ''
        openssl rand -hex 32 | tr -d '\n' > "$out/key"
      '';
    };

    # shell command for a vars generator that depends on meilisearch-master;
    # prints the tenant's api key, HMAC-SHA256(master key, key uid), which is
    # the value meilisearch gives a key created with that uid
    tenantKey =
      pkgs: tenant:
      "${pkgs.lib.getExe pkgs.python3} -c 'import hmac, sys; print(hmac.new(open(sys.argv[1], \"rb\").read(), sys.argv[2].encode(), \"sha256\").hexdigest())' \"$in/meilisearch-master/key\" ${
        config.flake.meilisearch.tenants.${tenant}.uid
      }";
  };

  flake.modules.nixos.meilisearch =
    {
      flake-self,
      config,
      lib,
      pkgs,
      ...
    }:
    let
      localHost = lib.removePrefix "https://" flake-self.meilisearch.url;
      listenUrl = "http://127.0.0.1:${toString listenPort}";
      generators = config.clan.core.vars.generators;
      tenantKeys = lib.mapAttrsToList (name: tenant: {
        inherit name;
        inherit (tenant) uid indexes actions;
        expiresAt = null;
      }) flake-self.meilisearch.tenants;
    in
    {
      clan.core.vars.generators.meilisearch-master = flake-self.meilisearch.masterGenerator pkgs;

      clan.core.vars.generators.meilisearch = {
        dependencies = [ "meilisearch-master" ];
        files.master-key.restartUnits = [ "meilisearch.service" ];
        script = ''
          cp "$in/meilisearch-master/key" "$out/master-key"
        '';
      };

      services.meilisearch = {
        enable = true;
        listenAddress = "127.0.0.1";
        inherit listenPort;
        masterKeyFile = generators.meilisearch.files.master-key.path;
        # production refuses to start without a master key and has no web ui
        settings.env = "production";
      };

      # meilisearch keeps api keys in its database; create the tenant keys
      systemd.services.meilisearch-keys = {
        description = "create the meilisearch tenant api keys";
        wantedBy = [ "multi-user.target" ];
        after = [ "meilisearch.service" ];
        requires = [ "meilisearch.service" ];
        partOf = [ "meilisearch.service" ];
        path = [
          pkgs.curl
          pkgs.jq
        ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          DynamicUser = true;
          LoadCredential = "master-key:${generators.meilisearch.files.master-key.path}";
          RuntimeDirectory = "meilisearch-keys";
          WorkingDirectory = "/run/meilisearch-keys";
        };
        script = ''
          api() {
            curl --silent --show-error \
              --header "Authorization: Bearer $(cat "$CREDENTIALS_DIRECTORY/master-key")" \
              --header 'Content-Type: application/json' "$@"
          }

          # the unit is simple, so it counts as started before it listens
          curl --silent --show-error --fail --retry 30 --retry-delay 1 --retry-connrefused \
            ${listenUrl}/health >/dev/null

          jq -c '.[]' ${pkgs.writeText "meilisearch-keys.json" (builtins.toJSON tenantKeys)} | while read -r key; do
            uid=$(jq -r .uid <<<"$key")
            status=$(api --output current.json --write-out '%{http_code}' "${listenUrl}/keys/$uid")
            if [ "$status" = 200 ]; then
              # actions and indexes of a key cannot be changed
              if jq -e --argjson key "$key" \
                '.actions == $key.actions and .indexes == $key.indexes' current.json >/dev/null; then
                continue
              fi
              api --fail-with-body --request DELETE "${listenUrl}/keys/$uid"
            elif [ "$status" != 404 ]; then
              cat current.json >&2
              exit 1
            fi
            api --fail-with-body --request POST --data-binary "$key" ${listenUrl}/keys >/dev/null
            echo "created key $(jq -r .name <<<"$key")"
          done
        '';
      };

      services.gatus.settings.endpoints = [
        {
          name = "Meilisearch";
          url = "https://${localHost}/health";
          enabled = true;
          alerts = [ { type = "matrix"; } ];
          interval = "5m";
          conditions = [ "[STATUS] == 200" ];
        }
      ];

      # no proxy-auth - meilisearch refuses requests without an api key
      services.caddy.virtualHosts.${localHost}.extraConfig = ''
        reverse_proxy ${listenUrl}
      '';

      # DynamicUser service: state lives in /var/lib/private/meilisearch,
      # covered by host-level /var/lib preservation.
    };
}

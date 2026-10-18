{
  # machines tab: an export job reads the local beszel hub as its readonly
  # reader (beszel clan service) into machines.json; machines.js renders it
  # over the beszel module's machine tiles
  flake.modules.nixos.homepage =
    {
      config,
      flake-self,
      lib,
      pkgs,
      ...
    }:
    let
      hub = config.services.beszel.hub;
      api = "http://${hub.host}:${toString hub.port}/api";

      # beszel collects no addresses; flake.hosts and flake.router hold the
      # static ones, keyed by beszel system name
      toAddresses = lib.mapAttrsToList (label: address: { inherit label address; });
      addresses = lib.mapAttrs (_: toAddresses) flake-self.hosts // {
        openwrt = toAddresses flake-self.router;
      };

      exportScript = pkgs.writeShellScript "homepage-beszel-export" ''
        set -euo pipefail
        export PATH=${
          lib.makeBinPath [
            pkgs.curl
            pkgs.jq
            pkgs.coreutils
          ]
        }

        # the password and token stay out of argv, which any uid can read
        umask 077
        jq -cn '{identity: $ENV.BESZEL_READER_EMAIL, password: $ENV.BESZEL_READER_PASSWORD}' \
          | curl -sf -X POST ${api}/collections/users/auth-with-password \
              -H 'content-type: application/json' --data-binary @- \
          | jq -r '"Authorization: \(.token)"' > /tmp/auth.header

        get() {
          curl -sf -H @/tmp/auth.header "${api}/collections/$1/records?perPage=500&fields=$2"
        }
        get systems id,name,status,info > /tmp/systems.json
        get system_details system,os_name,kernel,cpu,cores,memory > /tmp/details.json
        get zfs_pools system,name,display_name,health,size,alloc,scrub,vdevs,datasets > /tmp/pools.json
        get smart_devices system,name,model,serial,state,capacity,temp,hours > /tmp/smart.json
        for id in $(jq -r '.items[].id' /tmp/systems.json); do
          curl -sf -H @/tmp/auth.header \
            "${api}/collections/system_stats/records?filter=(system%3D%27$id%27%26%26type%3D%271m%27)&sort=-created&perPage=1&fields=system,stats" \
            | jq -c '.items[0] // empty'
        done > /tmp/stats.jsonl

        out=$RUNTIME_DIRECTORY/machines.json
        jq -n \
          --slurpfile systems /tmp/systems.json \
          --slurpfile details /tmp/details.json \
          --slurpfile pools /tmp/pools.json \
          --slurpfile smart /tmp/smart.json \
          --slurpfile stats /tmp/stats.jsonl \
          -f ${./machines.jq} > "$out.tmp"
        chmod 0644 "$out.tmp"
        mv "$out.tmp" "$out"
      '';
    in
    # the reader var and the machine tiles exist only next to the hub
    lib.mkIf hub.enable {
      services.homepage-dashboard.customCSS = builtins.readFile ./machines.css;
      services.homepage-dashboard.customJS = ''
        window.homepageMachineAddresses = ${builtins.toJSON addresses};
        ${builtins.readFile ./machines.js}
      '';

      services.caddy.virtualHosts."home.${flake-self.domains.local}".extraConfig = ''
        handle /machines.json {
          root * /run/homepage-beszel
          file_server
        }
      '';

      systemd.services.homepage-beszel-export = {
        description = "Export beszel machines, pools and drives for the homepage machines tab";
        after = [ "beszel-reader.service" ];
        wants = [ "beszel-reader.service" ];
        serviceConfig = {
          Type = "oneshot";
          # a static user: with DynamicUser a preserved RuntimeDirectory moves
          # under /run/private (0700), where caddy cannot reach it
          User = "homepage-beszel";
          Group = "homepage-beszel";
          EnvironmentFile = config.clan.core.vars.generators.beszel-reader.files.env.path;
          ExecStart = exportScript;
          # caddy reads the export, so the directory and file are world-readable
          RuntimeDirectory = "homepage-beszel";
          RuntimeDirectoryMode = "0755";
          RuntimeDirectoryPreserve = "yes";
          PrivateTmp = true;
          ProtectHome = true;
          ProtectSystem = "strict";
          NoNewPrivileges = true;
        };
      };

      systemd.timers.homepage-beszel-export = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "1min";
          OnUnitActiveSec = "30s";
          AccuracySec = "5s";
        };
      };

      users.users.homepage-beszel = {
        isSystemUser = true;
        group = "homepage-beszel";
      };
      users.groups.homepage-beszel = { };
    };
}

{
  flake.modules.nixos.arrStack =
    { lib, pkgs, ... }:
    let
      keyFile = serviceName: "/run/arr-api-keys/${serviceName}.api-key";

      ports = {
        prowlarr = 9696;
        sonarr = 8989;
        radarr = 7878;
        lidarr = 8686;
        sabnzbd = 8085;
      };
      baseUrl = serviceName: "http://127.0.0.1:${toString ports.${serviceName}}";

      # an entry is upserted by name. an existing resource is used as the base
      # so anything set in the ui and not declared here survives; only declared
      # fields are forced.
      mkEntry =
        {
          apiVersion,
          resource,
          entry,
        }:
        ''
          overrides=$(jq -n --argjson lit ${lib.escapeShellArg (builtins.toJSON entry.fields)}${
            lib.concatStrings (
              lib.mapAttrsToList (
                fieldName: path: " --arg secret_${fieldName} \"$(cat ${path})\""
              ) entry.secretFields
            )
          } '$lit${
            lib.concatStrings (
              lib.mapAttrsToList (fieldName: _: " + {\"${fieldName}\": $secret_${fieldName}}") entry.secretFields
            )
          }')

          existing=$(curl -sfS -H "X-Api-Key: $own" "$base/api/${apiVersion}/${resource}" \
            | jq -c --arg name ${lib.escapeShellArg entry.name} 'map(select(.name == $name)) | first // empty')

          if [ -n "$existing" ]; then
            start=$existing
          else
            start=$(curl -sfS -H "X-Api-Key: $own" "$base/api/${apiVersion}/${resource}/schema" \
              | jq -ce --arg impl ${lib.escapeShellArg entry.implementation} \
                  'map(select(.implementation == $impl)) | first // error("no schema for \($impl)")')
          fi

          body=$(printf '%s' "$start" | jq -ce \
            --arg name ${lib.escapeShellArg entry.name} \
            --argjson top ${lib.escapeShellArg (builtins.toJSON entry.top)} \
            --argjson ov "$overrides" '
              . * $top
              | .name = $name
              | .fields |= map(.name as $field | if ($ov | has($field)) then .value = $ov[$field] else . end)')

          if [ -n "$existing" ]; then
            id=$(printf '%s' "$existing" | jq -r .id)
            curl -sfS -X PUT -H "X-Api-Key: $own" -H 'Content-Type: application/json' \
              -d "$body" "$base/api/${apiVersion}/${resource}/$id" >/dev/null
            echo "updated ${resource} ${entry.name} (id $id)"
          else
            curl -sfS -X POST -H "X-Api-Key: $own" -H 'Content-Type: application/json' \
              -d "$body" "$base/api/${apiVersion}/${resource}" >/dev/null
            echo "created ${resource} ${entry.name}"
          fi
        '';

      # a curl command that must succeed before the upsert runs. the *arr apps
      # validate a download client by connecting to it, so the target has to be
      # answering, not merely started.
      waitFor = check: ''
        ready=""
        for _ in $(seq 60); do
          if ${check} >/dev/null 2>&1; then
            ready=yes
            break
          fi
          sleep 2
        done

        if [ -z "$ready" ]; then
          echo "not ready: ${check}" >&2
          exit 1
        fi
      '';

      mkSyncUnit =
        {
          host,
          apiVersion,
          resource,
          entries,
          needsKeys,
          readyChecks ? [ ],
        }:
        {
          description = "sync ${resource} into ${host}";
          after = [ "${host}.service" ] ++ map (serviceName: "${serviceName}-api.service") needsKeys;
          requires = map (serviceName: "${serviceName}-api.service") needsKeys;
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            DynamicUser = true;
            SupplementaryGroups = map (serviceName: "${serviceName}-api") needsKeys;
            ProtectSystem = "strict";
            ProtectHome = true;
            PrivateDevices = true;
            NoNewPrivileges = true;
            RestrictAddressFamilies = [
              "AF_INET"
              "AF_INET6"
            ];
            CapabilityBoundingSet = "";
            ExecStart = pkgs.writeShellScript "sync-${host}-${resource}" ''
              set -eu
              export PATH=${
                lib.makeBinPath [
                  pkgs.coreutils
                  pkgs.curl
                  pkgs.jq
                ]
              }

              own=$(cat ${keyFile host})
              base=${baseUrl host}

              ${waitFor ''curl -sfS -H "X-Api-Key: $own" "$base/api/${apiVersion}/system/status"''}
              ${lib.concatMapStringsSep "\n" waitFor readyChecks}
              ${lib.concatMapStringsSep "\n" (entry: mkEntry { inherit apiVersion resource entry; }) entries}
            '';
          };
        };

      arrs = {
        sonarr = {
          apiVersion = "v3";
          categoryField = "tvCategory";
          category = "tv";
        };
        radarr = {
          apiVersion = "v3";
          categoryField = "movieCategory";
          category = "movies";
        };
        lidarr = {
          apiVersion = "v1";
          categoryField = "musicCategory";
          category = "music";
        };
      };
    in
    {
      config.systemd.services = {
        prowlarr-app-sync = mkSyncUnit {
          host = "prowlarr";
          apiVersion = "v1";
          resource = "applications";
          needsKeys = [ "prowlarr" ] ++ lib.attrNames arrs;
          entries = lib.mapAttrsToList (serviceName: _: {
            name = lib.toSentenceCase serviceName;
            implementation = lib.toSentenceCase serviceName;
            top.syncLevel = "fullSync";
            fields = {
              prowlarrUrl = baseUrl "prowlarr";
              baseUrl = baseUrl serviceName;
            };
            secretFields.apiKey = keyFile serviceName;
          }) arrs;
        };
      }
      // lib.mapAttrs' (
        serviceName: arr:
        lib.nameValuePair "${serviceName}-downloadclient-sync" (mkSyncUnit {
          host = serviceName;
          inherit (arr) apiVersion;
          resource = "downloadclient";
          needsKeys = [
            serviceName
            "sabnzbd"
          ];
          readyChecks = [
            ''curl -sfS "${baseUrl "sabnzbd"}/api?mode=version&apikey=$(cat ${keyFile "sabnzbd"})"''
          ];
          entries = [
            {
              name = "SABnzbd";
              implementation = "Sabnzbd";
              top.enable = true;
              # sabnzbd host_whitelist rejects unknown Host headers; localhost passes
              fields = {
                host = "localhost";
                port = ports.sabnzbd;
                ${arr.categoryField} = arr.category;
              };
              secretFields.apiKey = keyFile "sabnzbd";
            }
          ];
        })
      ) arrs;
    };
}

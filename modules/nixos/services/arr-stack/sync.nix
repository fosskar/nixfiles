{
  flake.modules.nixos.arrStack =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      keyFile = serviceName: "/run/arr-api-keys/${serviceName}/api-key";
      # prowlarr writes its own key from ExecStartPost (api-keys.nix)
      keyUnit =
        serviceName: if serviceName == "prowlarr" then "prowlarr.service" else "${serviceName}-api.service";

      ports = {
        prowlarr = 9696;
        sonarr = 8989;
        radarr = 7878;
        lidarr = 8686;
        chaptarr = 8789;
        sabnzbd = 8085;
      };
      baseUrl = serviceName: "http://127.0.0.1:${toString ports.${serviceName}}";
      audiobookshelfUrl = "http://127.0.0.1:13378/audiobookshelf";

      # an entry is upserted by name. an existing resource is used as the base
      # so anything set in the ui and not declared here survives; only declared
      # fields are forced.
      mkEntry =
        {
          apiVersion,
          resource,
          entry,
        }:
        let
          # top-level json computed at runtime: key -> file holding the value
          topFiles = entry.topFiles or { };
        in
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
            --argjson top ${lib.escapeShellArg (builtins.toJSON entry.top)}${
              lib.concatStrings (lib.mapAttrsToList (key: path: " --slurpfile topfile_${key} ${path}") topFiles)
            } \
            --argjson ov "$overrides" '
              . * $top${
                lib.concatStrings (lib.mapAttrsToList (key: _: " | .${key} = $topfile_${key}[0]") topFiles)
              }
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
          # keys that are not under /run/arr-api-keys: name -> file, read from
          # $CREDENTIALS_DIRECTORY/<name>
          credentials ? { },
          extraUnits ? [ ],
          # shell run after the ready checks, before the upserts
          prepare ? "",
        }:
        {
          description = "sync ${resource} into ${host}";
          after = [ "${host}.service" ] ++ map keyUnit needsKeys ++ extraUnits;
          requires = map keyUnit needsKeys ++ extraUnits;
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
            LoadCredential = lib.mapAttrsToList (name: path: "${name}:${path}") credentials;
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
              ${prepare}
              ${lib.concatMapStringsSep "\n" (entry: mkEntry { inherit apiVersion resource entry; }) entries}
            '';
          };
        };

      arrs = {
        sonarr = {
          apiVersion = "v3";
          prowlarrApp = "Sonarr";
          categories.tvCategory = "tv";
        };
        radarr = {
          apiVersion = "v3";
          prowlarrApp = "Radarr";
          categories.movieCategory = "movies";
        };
        lidarr = {
          apiVersion = "v1";
          prowlarrApp = "Lidarr";
          categories.musicCategory = "music";
        };
        # prowlarr has no chaptarr app; chaptarr keeps the readarr v1 api
        chaptarr = {
          apiVersion = "v1";
          prowlarrApp = "Readarr";
          categories = {
            audiobookCategory = "audiobooks";
            ebookCategory = "ebooks";
          };
        };
      };
    in
    {
      config.systemd.services = {
        # chaptarr tells audiobookshelf exactly which files it imported, renamed
        # or deleted. the mappings pair chaptarr root folders with audiobookshelf
        # library folders by path; both only exist at runtime.
        chaptarr-audiobookshelf-sync = mkSyncUnit {
          host = "chaptarr";
          apiVersion = "v1";
          resource = "notification";
          needsKeys = [ "chaptarr" ];
          credentials.audiobookshelf-api-key =
            config.clan.core.vars.generators.audiobookshelf-api.files.api-key.path;
          extraUnits = [ "audiobookshelf.service" ];
          readyChecks = [ ''curl -sfS "${audiobookshelfUrl}/status"'' ];
          prepare = ''
            abs_key=$(cat "$CREDENTIALS_DIRECTORY/audiobookshelf-api-key")
            roots=$(curl -sfS -H "X-Api-Key: $own" "$base/api/v1/rootfolder")
            libraries=$(curl -sfS -H "Authorization: Bearer $abs_key" "${audiobookshelfUrl}/api/libraries")
            jq -nce --argjson roots "$roots" --argjson libraries "$libraries" '
              [ $roots[] as $root
                | $libraries.libraries[] as $library
                | $library.folders[]
                | select(.fullPath == $root.path)
                | { RootFolderId: $root.id,
                    MediaType: (if $root.folderType == 2 then "ebook" else "audiobook" end),
                    LibraryId: $library.id,
                    LibraryFolderId: .id,
                    LibraryFolderPath: .fullPath } ]
              | if length == 0 then error("no audiobookshelf folder matches a chaptarr root folder") else . end
            ' > /tmp/audiobookshelf-library-mappings
          '';
          entries = [
            {
              name = "AudioBookShelf";
              implementation = "AudioBookShelf";
              top = {
                onReleaseImport = true;
                onUpgrade = true;
                onRename = true;
                onBookFileDelete = true;
                onBookFileDeleteForUpgrade = true;
              };
              fields = {
                host = "127.0.0.1";
                port = 13378;
                useSsl = false;
                urlBase = "/audiobookshelf";
              };
              secretFields.apiKey = "$CREDENTIALS_DIRECTORY/audiobookshelf-api-key";
              # chaptarr takes the mappings from this top-level field and
              # overwrites libraryMappingsJson with it
              topFiles.audioBookShelfLibraryMappings = "/tmp/audiobookshelf-library-mappings";
            }
          ];
        };

        prowlarr-app-sync = mkSyncUnit {
          host = "prowlarr";
          apiVersion = "v1";
          resource = "applications";
          needsKeys = [ "prowlarr" ] ++ lib.attrNames arrs;
          readyChecks = lib.mapAttrsToList (
            serviceName: arr:
            ''curl -sfS -H "X-Api-Key: $(cat ${keyFile serviceName})" "${baseUrl serviceName}/api/${arr.apiVersion}/system/status"''
          ) arrs;
          entries = lib.mapAttrsToList (serviceName: arr: {
            name = lib.toSentenceCase serviceName;
            implementation = arr.prowlarrApp;
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
              }
              // arr.categories;
              secretFields.apiKey = keyFile "sabnzbd";
            }
          ];
        })
      ) arrs;
    };
}

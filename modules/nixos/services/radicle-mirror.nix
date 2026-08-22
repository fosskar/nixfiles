{
  flake.modules.nixos.radicleMirror =
    {
      flake-self,
      config,
      lib,
      pkgs,
      ...
    }:
    let
      publicHost = "radicle.${flake-self.domains.public}";
      mirrorPort = 4128;
      apiPort = 8080;
      searchPort = 7700;
      explorerPort = 8090;
      anubisPort = 8097;
      publicPort = 8098;
      nodePort = 8776;
      seedRepositories = [
        "rad:z4X1gDvBMpZLyzkQEj7dCMpurwqkV"
        "rad:z5CtgCW1jHxrty8g192NZYVG7S7H"
        "rad:zMmPXt7SUuhRQuodAjvy8owU8CoF"
        "rad:z2meKz6mpGHaWFhmxmC15wpS2Zjb1"
        "rad:z27Hv7yHKZG5df2u9PQnUfRV7VRcb"
      ];
      generators = config.clan.core.vars.generators;
      credentialsDirectory = "/run/credentials/radicle-mirror.service";

      explorer = pkgs.radicle-explorer.withConfig {
        nodes.homepage = "explore";
        preferredSeeds = [
          {
            hostname = publicHost;
            port = 443;
            scheme = "https";
          }
        ];
      };

    in
    {
      imports = [ flake-self.inputs.radicle-mirror.nixosModules.default ];

      services.radicle-mirror = {
        enable = true;
        package = flake-self.inputs.radicle-mirror.packages.${pkgs.stdenv.hostPlatform.system}.default;
        addr = "127.0.0.1:${toString mirrorPort}";
        ghAppId = 4631493;
        ghAppKeyPath = "${credentialsDirectory}/gh-app-key";
        webhookSecretPath = "${credentialsDirectory}/webhook-secret";
        radicleKeyPath = "${credentialsDirectory}/radicle-key";
        allowedOwners = [ "fosskar" ];
        delegates = [
          "did:key:z6MkuikgFx2EtrJufK4vYELecHj7Qg5cTpBRZHhsb8t9M8Qq"
          "did:key:z6Mkqumzp6etEF91c57YnvHkrwq4DkUqVusTSTdychiEDLLJ"
          "did:key:z6MkjNSSqPTQm5AnKdmgVom22nr4ZK57bj7dSm1gZeFX4MxN"
        ];
        p2pListen = [ "0.0.0.0:${toString nodePort}" ];
        p2pExternalAddresses = [ "seed.${flake-self.domains.public}:${toString nodePort}" ];
      };

      systemd.services.radicle-mirror = {
        conflicts = [ "radicle-node.service" ];
        after = [ "radicle-node.service" ];
        postStart = ''
          config="$STATE_DIRECTORY/rad/config.json"
          temporary="$(mktemp "$STATE_DIRECTORY/rad/config.json.XXXXXX")"
          ${lib.getExe pkgs.jq} \
            --argjson repositories ${lib.escapeShellArg (builtins.toJSON seedRepositories)} \
            '.web.pinned.repositories = $repositories' \
            "$config" > "$temporary"
          chmod --reference="$config" "$temporary"
          mv "$temporary" "$config"
        '';
        serviceConfig.LoadCredential = [
          "gh-app-key:${generators.radicle-mirror-github-key.files.private-key.path}"
          "webhook-secret:${generators.radicle-mirror-github.files.webhook-secret.path}"
          "radicle-key:${generators.radicle-mirror-key.files.private-key.path}"
        ];
      };

      clan.core.vars.generators = {
        radicle-mirror-github = {
          files.webhook-secret.secret = true;
          runtimeInputs = [ pkgs.openssl ];
          script = ''
            openssl rand -hex 32 > "$out/webhook-secret"
          '';
        };

        radicle-mirror-github-key = {
          files.private-key.secret = true;
          prompts.private-key = {
            description = "GitHub App private key (PEM) for radicle-mirror";
            type = "multiline";
            persist = true;
          };
          script = ''
            cp "$prompts/private-key" "$out/private-key"
          '';
        };

        radicle-mirror-key = {
          files.private-key.secret = true;
          files.public-key.secret = false;
          runtimeInputs = [ pkgs.openssh ];
          script = ''
            ssh-keygen -t ed25519 -N "" -C radicle-mirror -f "$out/private-key"
            mv "$out/private-key.pub" "$out/public-key"
          '';
        };
      };

      services.meilisearch = {
        enable = true;
        listenAddress = "127.0.0.1";
        listenPort = searchPort;
      };

      systemd.services.radicle-search = {
        description = "Radicle repository search indexer";
        wantedBy = [ "multi-user.target" ];
        after = [
          "meilisearch.service"
          "radicle-mirror.service"
        ];
        requires = [
          "meilisearch.service"
          "radicle-mirror.service"
        ];
        serviceConfig = {
          ExecStart = lib.getExe' pkgs.radicle-httpd "radicle-search";
          Environment = [
            "RAD_HOME=/var/lib/radicle-mirror/rad"
            "RADICLE_SEARCH_MEILI_URL=http://127.0.0.1:${toString searchPort}"
          ];
          Restart = "on-failure";
          RestartSec = 5;
          DynamicUser = true;
          User = "radicle-mirror";
          StateDirectory = "radicle-mirror";
          NoNewPrivileges = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          PrivateTmp = true;
          PrivateDevices = true;
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectControlGroups = true;
          RestrictAddressFamilies = [
            "AF_INET"
            "AF_INET6"
            "AF_UNIX"
          ];
          RestrictNamespaces = true;
          LockPersonality = true;
          MemoryDenyWriteExecute = true;
          SystemCallArchitectures = "native";
        };
      };

      systemd.services.radicle-httpd = {
        description = "Radicle HTTP gateway";
        wantedBy = [ "multi-user.target" ];
        wants = [ "radicle-search.service" ];
        after = [
          "radicle-mirror.service"
          "radicle-search.service"
        ];
        requires = [ "radicle-mirror.service" ];
        serviceConfig = {
          ExecStart = "${lib.getExe pkgs.radicle-httpd} --listen 127.0.0.1:${toString apiPort}";
          Environment = [
            "RAD_HOME=/var/lib/radicle-mirror/rad"
            "RADICLE_SEARCH_URL=http://127.0.0.1:${toString searchPort}"
          ];
          Restart = "on-failure";
          RestartSec = 5;
          DynamicUser = true;
          User = "radicle-mirror";
          StateDirectory = "radicle-mirror";
          NoNewPrivileges = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          PrivateTmp = true;
          PrivateDevices = true;
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectControlGroups = true;
          RestrictAddressFamilies = [
            "AF_INET"
            "AF_INET6"
            "AF_UNIX"
          ];
          RestrictNamespaces = true;
          LockPersonality = true;
          MemoryDenyWriteExecute = true;
          SystemCallArchitectures = "native";
        };
      };

      services.nginx.virtualHosts = {
        radicle = {
          listen = [
            {
              addr = "127.0.0.1";
              port = explorerPort;
            }
          ];
          root = "${explorer}";
          locations."/" = {
            tryFiles = "$uri $uri/ /index.html =404";
            extraConfig = ''
              expires 1h;
              add_header Cache-Control "public, immutable";
            '';
          };
          locations."/api/" = {
            proxyPass = "http://127.0.0.1:${toString apiPort}";
            recommendedProxySettings = true;
          };
          locations."/raw/" = {
            proxyPass = "http://127.0.0.1:${toString apiPort}";
            recommendedProxySettings = true;
          };
        };

        radicle-public = {
          listen = [
            {
              addr = "0.0.0.0";
              port = publicPort;
            }
          ];
          locations."= /github" = {
            proxyPass = "http://127.0.0.1:${toString mirrorPort}";
            recommendedProxySettings = true;
          };
          locations."/" = {
            proxyPass = "http://127.0.0.1:${toString anubisPort}";
            recommendedProxySettings = true;
          };
        };
      };

      services.anubis.instances.radicle.settings = {
        TARGET = "http://127.0.0.1:${toString explorerPort}";
        BIND = "127.0.0.1:${toString anubisPort}";
        BIND_NETWORK = "tcp";
        METRICS_BIND = "127.0.0.1:8099";
        METRICS_BIND_NETWORK = "tcp";
      };

      services.homepage-dashboard.services = [
        {
          code = [
            {
              Radicle = {
                href = "https://${publicHost}/";
                icon = "sh-radicle";
                siteMonitor = "https://${publicHost}/";
              };
            }
          ];
        }
      ];

      services.gatus.settings.endpoints = [
        {
          name = "Radicle";
          url = "https://${publicHost}/";
          enabled = true;
          alerts = [ { type = "email"; } ];
          interval = "5m";
          conditions = [ "[STATUS] == 200" ];
        }
      ];
    };
}

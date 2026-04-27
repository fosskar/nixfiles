{
  flake.modules.nixos.radicle =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      serviceName = "radicle";
      publicHost = "${serviceName}.${config.domains.public}";
      explorerPort = 8090;
      nodePort = 8776;
      cfg = config.services.radicle;

      # canonical public seeds. domains migrated from radicle.xyz in 2025
      # (see https://radicle.dev/blog). NIDs unchanged.
      bootstrapSeeds = [
        "z6MkrLMMsiPWUcNPHcRajuMi9mDfYckSoJyPwwnknocNYPm7@iris.radicle.network:58776"
        "z6MksmpU5b1dS7oaqF2bHXhQi1DWy2hB7Mh9CuN7y1DN6QSz@seed.radicle.dev:58776"
        "z6Mkmqogy2qEM2ummccUthFEaaHvyYmYBYh3dbe9W4ebScxo@rosa.radicle.network:58776"
      ];

      explorer = pkgs.radicle-explorer.withConfig {
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
      options.services.radicle.seedRepositories = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "rad:z4X1gDvBMpZLyzkQEj7dCMpurwqkV" # nixfiles
        ];
        description = ''
          radicle repository ids to whitelist (`rad seed`) and pin in the explorer.
        '';
      };

      config = {
        clan.core.vars.generators.radicle = {
          files."ssh-private-key" = {
            secret = true;
            owner = "radicle";
            group = "radicle";
            mode = "0600";
          };
          files."ssh-public-key".secret = false;
          runtimeInputs = [ pkgs.openssh ];
          script = ''
            ssh-keygen -t ed25519 -N "" -f "$out/ssh-private-key" -C "radicle@${config.networking.hostName}"
            ssh-keygen -y -f "$out/ssh-private-key" > "$out/ssh-public-key"
          '';
        };

        services.radicle = {
          enable = true;
          privateKey = config.clan.core.vars.generators.radicle.files."ssh-private-key".path;
          publicKey = config.clan.core.vars.generators.radicle.files."ssh-public-key".path;
          node.listenPort = nodePort;
          httpd = {
            enable = true;
            listenAddress = "127.0.0.1";
            nginx = {
              serverName = "radicle";
              listen = [
                {
                  addr = "0.0.0.0";
                  port = explorerPort;
                }
              ];
              forceSSL = false;
              enableACME = false;
            };
          };

          settings = {
            preferredSeeds = bootstrapSeeds;
            node = {
              externalAddresses = [ "seed.fosskar.eu:${toString nodePort}" ];
              alias = "radicle.fosskar.eu";
              connect = bootstrapSeeds;
            };
            web.pinned.repositories = cfg.seedRepositories;
          };
        };

        systemd.services.radicle-node-setup = {
          description = "seed configured radicle repositories";
          after = [ "radicle-node.service" ];
          wants = [ "radicle-node.service" ];
          wantedBy = [ "multi-user.target" ];
          environment = {
            HOME = "/var/lib/radicle";
            RAD_HOME = "/var/lib/radicle";
          };
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            User = "radicle";
            Group = "radicle";
            LoadCredential = "radicle:${cfg.privateKey}";
            BindReadOnlyPaths = [
              "${cfg.configFile}:/var/lib/radicle/config.json"
              "/run/credentials/radicle-node-setup.service/radicle:/var/lib/radicle/keys/radicle"
              "${cfg.publicKey}:/var/lib/radicle/keys/radicle.pub"
            ];
            StateDirectory = "radicle";
            StateDirectoryMode = "0750";
          };
          path = [ cfg.package ];
          script = ''
            # wait for radicle-node to be ready
            for _ in $(seq 1 30); do
              if rad node status &>/dev/null; then
                break
              fi
              sleep 1
            done

            ${lib.concatMapStringsSep "\n" (rid: ''
              rad seed ${lib.escapeShellArg rid} --scope all || true
            '') cfg.seedRepositories}
          '';
        };

        services.nginx.virtualHosts."radicle" = {
          root = lib.mkForce "${explorer}";
          locations."/" = {
            proxyPass = lib.mkForce null;
            tryFiles = "$uri $uri/ /index.html =404";
            extraConfig = ''
              expires 1h;
              add_header Cache-Control "public, immutable";
            '';
          };
          locations."/api/" = {
            proxyPass = "http://127.0.0.1:${toString config.services.radicle.httpd.listenPort}";
            recommendedProxySettings = true;
          };
        };

        networking.firewall.allowedTCPPorts = [ explorerPort ];
      };
    };
}

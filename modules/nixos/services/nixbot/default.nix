{
  flake.modules.nixos.nixbot =
    {
      flake-self,
      config,
      inputs,
      lib,
      pkgs,
      ...
    }:
    let
      serviceName = "nixbot";
      publicHost = "${serviceName}.${flake-self.domains.public}";
    in
    {
      imports = [ inputs.nixbot.nixosModules.nixbot ];

      config = {
        # cross-host: declared here on nixworker via the default options; nixbot
        # has no homepage/gatus locally, so these are inert until the homepage/
        # gatus host collects them across the clan.
        services.homepage-dashboard.services = [
          {
            "code" = [
              {
                "Nixbot" = {
                  href = "https://${publicHost}";
                  icon = "https://raw.githubusercontent.com/Mic92/nixbot/main/nixbot/nixbot/web/static/favicon.svg";
                  siteMonitor = "https://${publicHost}";
                };
              }
            ];
          }
        ];

        services.gatus.settings.endpoints = [
          {
            name = "Nixbot";
            url = "https://${publicHost}";
            enabled = true;
            alerts = [ { type = "email"; } ];
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }
        ];

        clan.core.vars.generators.nixbot-codeberg = {
          files.token = { };
          files.oauth-secret = { };
          prompts.token.description = "codeberg access token (write:repository, read:user, read:organization, write:issue)";
          prompts.oauth-secret.description = "codeberg oauth client secret";
          script = ''
            cp $prompts/token $out/token
            cp $prompts/oauth-secret $out/oauth-secret
          '';
        };

        clan.core.vars.generators.nixbot-github-app = {
          files."private-key.pem" = { };
          files."oauth-secret" = { };
          files."webhook-secret" = { };
          prompts.private-key.description = "github app private key (.pem)";
          prompts.private-key.type = "multiline-hidden";
          prompts.oauth-secret.description = "github app oauth client secret";
          script = ''
            cp $prompts/private-key $out/private-key.pem
            cp $prompts/oauth-secret $out/oauth-secret
            ${pkgs.openssl}/bin/openssl rand -hex 32 | tr -d '\n' >$out/webhook-secret
          '';
        };
        # shared with the authelia host (oidc-client.nix); clan requires
        # identical file sets on all definers, so both files deploy everywhere
        clan.core.vars.generators.nixbot-oidc = {
          share = true;
          files."oauth-client-secret" = { };
          files."oauth-client-secret-hash" = { };
          runtimeInputs = [
            pkgs.pwgen
            pkgs.authelia
          ];
          script = ''
            SECRET=$(pwgen -s 64 1)
            echo -n "$SECRET" > "$out/oauth-client-secret"
            authelia crypto hash generate pbkdf2 --password "$SECRET" | tail -1 | cut -d' ' -f2 > "$out/oauth-client-secret-hash"
          '';
        };

        services.nixbot = {
          enable = true;

          useHTTPS = true;
          domain = publicHost;

          admins = [
            "gitea:fosskar"
            "github:fosskar"
            # authelia opaque sub for the simon account
            "oidc:auth.${flake-self.domains.public}:d5103b45-c922-48f0-98fe-b9e249e32885"
          ];

          # group:admin only: private build logs can leak secrets
          privateRepoViewers."*" = [ "oidc:auth.${flake-self.domains.public}:group:admin" ];
          buildSystems = lib.mkDefault [ pkgs.stdenv.hostPlatform.system ];
          buildConcurrency = 4;
          # 16 cores / 92G; nixos evals eat 2-5G each, 12 leaves headroom
          evalWorkerCount = 12;
          cacheFailedBuilds = true;

          github = {
            enable = true;
            appId = 4238312;
            oauthId = "Iv23lilwHkCSxKsP6HOB";
            appSecretKeyFile = config.clan.core.vars.generators.nixbot-github-app.files."private-key.pem".path;
            webhookSecretFile = config.clan.core.vars.generators.nixbot-github-app.files."webhook-secret".path;
            oauthSecretFile = config.clan.core.vars.generators.nixbot-github-app.files."oauth-secret".path;
          };

          gitea = {
            enable = false;
            instanceUrl = "https://codeberg.org";
            tokenFile = config.clan.core.vars.generators.nixbot-codeberg.files."token".path;
            oauthSecretFile = config.clan.core.vars.generators.nixbot-codeberg.files."oauth-secret".path;
            oauthId = "a7b24f2c-1291-4566-970c-d39b869f0a35";
          };

          oidc = {
            enable = true;
            name = "Authelia";
            discoveryUrl = "https://auth.${flake-self.domains.public}/.well-known/openid-configuration";
            clientId = "nixbot";
            clientSecretFile = config.clan.core.vars.generators.nixbot-oidc.files."oauth-client-secret".path;
            scope = [
              "openid"
              "email"
              "profile"
              "groups"
            ];
            mapping.groups = "groups";
          };
        };
      };
    };
}

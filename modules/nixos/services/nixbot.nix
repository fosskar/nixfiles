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
            group = "Automation";
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

        clan.core.vars.generators.nixbot-github = {
          files."token" = { };
          prompts.token.description = "github PAT (no scopes) for the update-pkgs effect";
          script = ''
            ${pkgs.jq}/bin/jq -n --arg token "$(cat "$prompts/token")" \
              '{ "github-api": { condition: "isDefaultBranch", data: { token: $token } } }' \
              >"$out/token"
          '';
        };

        # persistent nix git/tarball cache for effects: the sandbox HOME is
        # throwaway, so without this every run re-fetches all flake inputs.
        systemd.tmpfiles.rules = [ "d /var/lib/nixbot/effects-nix-cache 0700 nixbot nixbot -" ];

        services.nixbot = {
          enable = true;

          useHTTPS = true;
          domain = publicHost;

          effects.perRepoSecretFiles."gitea:fosskar/*" =
            config.clan.core.vars.generators.nixbot-github.files."token".path;

          effects.mountables.nix-cache = {
            source = "/var/lib/nixbot/effects-nix-cache";
            readOnly = false;
            condition = {
              isOwner = "fosskar";
            };
          };

          admins = [
            "gitea:fosskar"
            "github:fosskar"
          ];
          buildSystems = lib.mkDefault [ pkgs.stdenv.hostPlatform.system ];
          buildConcurrency = 2;
          evalWorkerCount = lib.mkDefault 8;
          cacheFailedBuilds = true;

          gitea = {
            enable = true;
            instanceUrl = "https://codeberg.org";
            topic = "build-with-nixbot";
            tokenFile = config.clan.core.vars.generators.nixbot-codeberg.files."token".path;
            oauthSecretFile = config.clan.core.vars.generators.nixbot-codeberg.files."oauth-secret".path;
            oauthId = "a7b24f2c-1291-4566-970c-d39b869f0a35";
          };
        };
      };
    };
}

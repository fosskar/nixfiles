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
        services.homepage-dashboard.serviceGroups."code" = [
          {
            "Nixbot" = {
              href = "https://${publicHost}";
              icon = "buildbot.svg";
              siteMonitor = "https://${publicHost}";
            };
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

        clan.core.vars.generators.nixbot = {
          prompts.codeberg-token = {
            description = "codeberg api token for nixbot";
            type = "hidden";
            persist = true;
          };
          prompts.oauth-secret = {
            description = "codeberg oauth2 client secret";
            type = "hidden";
            persist = true;
          };
          prompts.oauth-id = {
            description = "codeberg oauth2 client id (uuid)";
            persist = true;
          };
          files."oauth-id".secret = false;
        };

        services.nixbot = {
          enable = true;

          useHTTPS = true;
          domain = publicHost;

          admins = [
            "gitea:fosskar"
            "github:fosskar"
            #"oidc:auth.${flake-self.domains.public}:d5103b45-c922-48f0-98fe-b9e249e32885"
          ];
          buildSystems = lib.mkDefault [ pkgs.stdenv.hostPlatform.system ];
          evalWorkerCount = lib.mkDefault 8;
          cacheFailedBuilds = true;

          gitea = {
            enable = true;
            instanceUrl = "https://codeberg.org";
            topic = "build-with-nixbot";
            tokenFile = config.clan.core.vars.generators.nixbot.files."codeberg-token".path;
            oauthSecretFile = config.clan.core.vars.generators.nixbot.files."oauth-secret".path;
            oauthId = config.clan.core.vars.generators.nixbot.files."oauth-id".value;
          };
        };
      };
    };
}

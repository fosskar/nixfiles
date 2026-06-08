{
  flake.modules.nixos.nixbot =
    {
      config,
      inputs,
      lib,
      pkgs,
      ...
    }:
    let
      serviceName = "nixbot";
      publicHost = "${serviceName}.${config.domains.public}";
    in
    {
      imports = [ inputs.nixbot.nixosModules.nixbot ];

      config = {
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
            #"oidc:auth.${config.domains.public}:d5103b45-c922-48f0-98fe-b9e249e32885"
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

          #oidc = {
          #  enable = true;
          #  name = "Authelia";
          #  discoveryUrl = "https://auth.${config.domains.public}/.well-known/openid-configuration";
          #  clientId = "nixbot";
          #  clientSecretFile = config.clan.core.vars.generators.nixbot.files."oidc-client-secret".path;
          #  scope = [
          #    "openid"
          #    "email"
          #    "profile"
          #    "groups"
          #  ];
          #  mapping.groups = "groups";
          #};

          # any authenticated authelia user may view private repos and their builds
          #privateRepoViewers."*" = [ "oidc:auth.${config.domains.public}:*" ];
        };
      };
    };
}

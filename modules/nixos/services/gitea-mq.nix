{
  flake.modules.nixos.giteaMq =
    {
      config,
      inputs,
      pkgs,
      ...
    }:
    let
      serviceName = "mq";
      publicHost = "${serviceName}.${config.domains.public}";
      backendPort = 8092;
      varsPath = config.clan.core.vars.generators.gitea-mq;
    in
    {
      imports = [ inputs.gitea-mq.nixosModules.default ];

      config = {
        clan.core.vars.generators.gitea-mq = {
          prompts.gitea-token = {
            description = "codeberg api token for gitea-mq (repo r/w + admin scope)";
            type = "hidden";
            persist = true;
          };
          files."webhook-secret".secret = true;

          runtimeInputs = [ pkgs.openssl ];
          script = ''
            openssl rand -hex 32 > "$out/webhook-secret"
          '';
        };

        services.gitea-mq = {
          enable = true;
          giteaUrl = "https://codeberg.org";
          giteaTokenFile = varsPath.files."gitea-token".path;
          webhookSecretFile = varsPath.files."webhook-secret".path;
          topic = "merge-queue";
          listenAddr = "0.0.0.0:${toString backendPort}";
          externalUrl = "https://${publicHost}";
          requiredChecks = [
            "nix-eval"
            "nix-build"
          ];
        };

        # postgres db + role; upstream module uses DynamicUser=true which resolves
        # to the unit name (gitea-mq), so peer auth on /run/postgresql works.
        services.postgresql.ensureDatabases = [ "gitea-mq" ];
        services.postgresql.ensureUsers = [
          {
            name = "gitea-mq";
            ensureDBOwnership = true;
          }
        ];

        # plain http vhost on :80; tls terminated upstream by netbird-proxy/traefik.
        services.nginx.virtualHosts.${publicHost} = {
          locations."/" = {
            proxyPass = "http://127.0.0.1:${toString backendPort}";
            extraConfig = ''
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;
            '';
          };
        };
      };
    };
}

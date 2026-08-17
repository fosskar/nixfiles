{
  # Alternative to flake.modules.nixos.nixbot: the same service run as a
  # flakelet, evaluated on the target at runtime instead of baked into the
  # system closure. Import exactly one of the two - both define the nixbot
  # user, the database and the same vars generators.
  flake.modules.nixos.flakeletNixbot =
    {
      flake-self,
      config,
      inputs,
      pkgs,
      ...
    }:
    let
      serviceName = "nixbot";
      publicHost = "${serviceName}.${flake-self.domains.public}";
      webUnixSocket = "/run/${serviceName}/web.sock";
      vars = config.clan.core.vars.generators;
    in
    {
      imports = [ inputs.flakelet.nixosModules.flakelet ];

      services.flakelets = {
        enable = true;
        services.${serviceName} = {
          # resolved on the machine at update time, independent of the
          # inputs.nixbot pin that provides nixbot-cli below
          flake = "github:Mic92/nixbot";
          settings = {
            user = serviceName;
            listen = webUnixSocket;

            credentials = {
              "github-app-secret-key" = vars.nixbot-github-app.files."private-key.pem".path;
              "github-webhook-secret" = vars.nixbot-github-app.files."webhook-secret".path;
              "github-oauth-secret" = vars.nixbot-github-app.files."oauth-secret".path;
              "oidc-client-secret" = vars.nixbot-oidc.files."oauth-client-secret".path;
            };

            # raw nixbot-config.json; every *_file value is a credential id
            # from the map above, not a path
            config = {
              url = "https://${publicHost}/";
              webhook_base_url = null;
              state_dir = "/var/lib/${serviceName}";
              gcroots_dir = "/nix/var/nix/gcroots/per-user/${serviceName}";
              db_url = "postgresql://${serviceName}@/${serviceName}?host=/run/postgresql";

              http_port = 8010;
              http_unix_socket = webUnixSocket;

              admins = [
                "gitea:fosskar"
                "github:fosskar"
                "oidc:auth.${flake-self.domains.public}:d5103b45-c922-48f0-98fe-b9e249e32885"
              ];
              private_repo_viewers."*" = [
                "oidc:auth.${flake-self.domains.public}:group:admin"
              ];

              build_systems = [ pkgs.stdenv.hostPlatform.system ];
              eval_systems = [ ];
              build_concurrency = 4;
              eval_worker_count = 12;
              eval_max_memory_size = 4096;
              build_max_silent_time = 1200;
              build_timeout = 10800;
              cache_failed_builds = true;

              github = {
                id = 4238312;
                api_url = "https://api.github.com";
                oauth_id = "Iv23lilwHkCSxKsP6HOB";
                secret_key_file = "github-app-secret-key";
                webhook_secret_file = "github-webhook-secret";
                oauth_secret_file = "github-oauth-secret";
                filters = {
                  user_allowlist = null;
                  repo_allowlist = null;
                  topic = "build-with-buildbot";
                };
              };
              gitea = null;
              gitlab = null;

              oidc = {
                name = "Authelia";
                discovery_url = "https://auth.${flake-self.domains.public}/.well-known/openid-configuration";
                client_id = serviceName;
                client_secret_file = "oidc-client-secret";
                scope = [
                  "openid"
                  "email"
                  "profile"
                  "groups"
                ];
                mapping = {
                  username = "sub";
                  groups = "groups";
                };
              };

              workload_identity = {
                enable = true;
                signing_key_file = null;
                token_ttl = 300;
                key_rotation_days = 30;
              };

              legacy_attr_prefix = false;
              status_context_prefix = serviceName;
              failed_build_report_limit = 47;
              branches = { };
              outputs_path = null;
              post_build_steps = [ ];
              pull_based = null;
              effects_per_repo_secrets = { };
              effects_extra_sandbox_paths = [ ];
              effects_extra_nix_options = { };
              effects_mountables_file = null;
              show_trace_on_failure = false;
              allow_unauthenticated_control = false;
              proxy_auth_header = null;
            };
          };
        };
      };

      # --- host side: the flakelet ships only nixbot.service and .socket ---

      users.users.${serviceName} = {
        isSystemUser = true;
        group = serviceName;
        home = "/var/lib/${serviceName}";
      };
      users.groups.${serviceName} = { };
      # the web socket is group-restricted (0660)
      users.users.nginx.extraGroups = [ serviceName ];

      nix.settings.extra-allowed-users = [ serviceName ];

      services.postgresql = {
        enable = true;
        ensureDatabases = [ serviceName ];
        ensureUsers = [
          {
            name = serviceName;
            ensureDBOwnership = true;
          }
        ];
      };

      # TLS terminates at the netbird-proxy on gateway, so plain http here.
      # Adding the flakelet-nginx bridge plus settings.domain would replace
      # this stanza with the service's own http/v1 export.
      services.nginx.virtualHosts.${publicHost}.locations."/" = {
        proxyPass = "http://unix:${webUnixSocket}";
        extraConfig = ''
          # github caps webhook payloads at 25 MB
          client_max_body_size 25m;
          proxy_connect_timeout 120s;
          proxy_send_timeout 120s;
          # long read timeout and no buffering keep SSE log streams alive
          proxy_read_timeout 3600s;
          proxy_buffering off;
        '';
      };

      environment.systemPackages = [
        inputs.nixbot.packages.${pkgs.stdenv.hostPlatform.system}.nixbot-cli
      ];
      environment.variables.NIXBOT_URL = "https://${publicHost}";

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

      # shared with the authelia host (services/nixbot/oidc-client.nix); clan
      # requires identical file sets on all definers
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
    };
}

{
  flake.modules.nixos.buildbotMaster =
    {
      config,
      inputs,
      lib,
      pkgs,
      ...
    }:
    let
      serviceName = "buildbot";
      publicHost = "${serviceName}.${config.domains.public}";
      workerCores = 16;
      varsPath = config.clan.core.vars.generators.buildbot-master;
    in
    {
      imports = [ inputs.buildbot-nix.nixosModules.buildbot-master ];

      config = {
        clan.core.vars.generators.buildbot-master = {
          prompts.codeberg-token = {
            description = "codeberg api token for buildbot";
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
          # oauth-id is not sensitive; keep it in the repo as a public var
          files."oauth-id".secret = false;

          files."worker-password".secret = true;
          files."workers.json".secret = true;
          files."webhook-secret".secret = true;

          runtimeInputs = [ pkgs.openssl ];

          script = ''
            WORKER_PASS=$(openssl rand -hex 32)
            echo -n "$WORKER_PASS" > "$out/worker-password"
            echo "[{\"name\": \"${config.networking.hostName}\", \"pass\": \"$WORKER_PASS\", \"cores\": ${toString workerCores}}]" > "$out/workers.json"
            openssl rand -hex 32 > "$out/webhook-secret"
          '';
        };

        services.buildbot-nix.master = {
          enable = true;
          useHTTPS = true;
          domain = publicHost;
          admins = [ "fosskar" ];
          buildSystems = lib.mkDefault [ pkgs.stdenv.hostPlatform.system ];
          evalWorkerCount = lib.mkDefault 8;
          cacheFailedBuilds = true;
          branches.giteaMq = {
            matchGlob = "gitea-mq/*";
            registerGCRoots = false;
            updateOutputs = false;
          };

          workersFile = varsPath.files."workers.json".path;
          authBackend = "gitea";

          gitea = {
            enable = true;
            instanceUrl = "https://codeberg.org";
            tokenFile = varsPath.files."codeberg-token".path;
            webhookSecretFile = varsPath.files."webhook-secret".path;
            oauthSecretFile = varsPath.files."oauth-secret".path;
            oauthId = varsPath.files."oauth-id".value;
          };
        };
      };
    };
}

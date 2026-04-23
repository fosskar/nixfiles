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
      workerCores = 16;
      varsPath = config.clan.core.vars.generators.buildbot-master;
    in
    {
      imports = [ inputs.buildbot-nix.nixosModules.buildbot-master ];

      config = {
        clan.core.vars.generators.buildbot-master = {
          prompts.codeberg-token.description = "codeberg api token for buildbot";
          prompts.codeberg-token.type = "hidden";
          prompts.oauth-secret.description = "codeberg oauth2 client secret";
          prompts.oauth-secret.type = "hidden";

          files."worker-password".secret = true;
          files."workers.json".secret = true;
          files."webhook-secret".secret = true;
          files."codeberg-token".secret = true;
          files."oauth-secret".secret = true;

          runtimeInputs = [ pkgs.openssl ];

          script = ''
            WORKER_PASS=$(openssl rand -hex 32)
            echo -n "$WORKER_PASS" > "$out/worker-password"
            echo "[{\"name\": \"${config.networking.hostName}\", \"pass\": \"$WORKER_PASS\", \"cores\": ${toString workerCores}}]" > "$out/workers.json"
            openssl rand -hex 32 > "$out/webhook-secret"

            cp "$prompts/codeberg-token" "$out/codeberg-token"
            cp "$prompts/oauth-secret" "$out/oauth-secret"
          '';
        };

        services.buildbot-master.extraConfig = ''
          c["www"]["port"] = "tcp:8010:interface=0.0.0.0"
        '';

        services.buildbot-nix.master = {
          enable = true;
          useHTTPS = true;
          buildSystems = lib.mkDefault [ pkgs.stdenv.hostPlatform.system ];
          evalWorkerCount = lib.mkDefault 8;

          workersFile = varsPath.files."workers.json".path;
          authBackend = "gitea";

          gitea = {
            enable = true;
            instanceUrl = "https://codeberg.org";
            tokenFile = varsPath.files."codeberg-token".path;
            webhookSecretFile = varsPath.files."webhook-secret".path;
            oauthSecretFile = varsPath.files."oauth-secret".path;
            topic = lib.mkDefault "build-with-buildbot";
          };
        };
      };
    };
}

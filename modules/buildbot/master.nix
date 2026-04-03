{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixfiles.buildbot.master;
  varsPath = config.clan.core.vars.generators.buildbot-master;
in
{
  imports = [ inputs.buildbot-nix.nixosModules.buildbot-master ];

  options.nixfiles.buildbot.master = {
    enable = lib.mkEnableOption "buildbot-nix master";

    domain = lib.mkOption {
      type = lib.types.str;
      description = "domain for buildbot web ui";
    };

    admins = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "users allowed to control builds";
    };

    buildSystems = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ pkgs.stdenv.hostPlatform.system ];
      description = "systems to build for";
    };

    workerCores = lib.mkOption {
      type = lib.types.int;
      default = 32;
      description = "cores/threads reported in workers.json";
    };

    codeberg = {
      oauthId = lib.mkOption {
        type = lib.types.str;
        description = "codeberg oauth2 application client id";
      };

      topic = lib.mkOption {
        type = lib.types.str;
        default = "build-with-buildbot";
        description = "codeberg topic to discover repos";
      };
    };
  };

  config = lib.mkIf cfg.enable {
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
        echo "[{\"name\": \"${config.networking.hostName}\", \"pass\": \"$WORKER_PASS\", \"cores\": ${toString cfg.workerCores}}]" > "$out/workers.json"
        openssl rand -hex 32 > "$out/webhook-secret"

        cp "$prompts/codeberg-token" "$out/codeberg-token"
        cp "$prompts/oauth-secret" "$out/oauth-secret"
      '';
    };

    # disable buildbot's auto-configured nginx; expose directly for netbird reverse proxy
    services.nginx.enable = lib.mkForce false;

    services.buildbot-master.extraConfig = ''
      c["www"]["port"] = "tcp:8010:interface=0.0.0.0"
    '';

    services.buildbot-nix.master = {
      enable = true;
      useHTTPS = true;
      inherit (cfg) domain admins buildSystems;

      workersFile = varsPath.files."workers.json".path;
      authBackend = "gitea";

      gitea = {
        enable = true;
        instanceUrl = "https://codeberg.org";
        tokenFile = varsPath.files."codeberg-token".path;
        webhookSecretFile = varsPath.files."webhook-secret".path;
        inherit (cfg.codeberg) oauthId;
        oauthSecretFile = varsPath.files."oauth-secret".path;
        inherit (cfg.codeberg) topic;
      };
    };
  };
}

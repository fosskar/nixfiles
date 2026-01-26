{
  config,
  pkgs,
  inputs,
  ...
}:
let
  stateDir = "/var/lib/clawdbot";
  inherit (inputs.nix-clawdbot.packages.${pkgs.stdenv.hostPlatform.system}) clawdbot;

  # secondary agents that share credentials with main
  secondaryAgents = [
    "simon"
    "iuser"
  ];
  configFile = pkgs.writeText "clawdbot.json" (
    builtins.toJSON {
      gateway = {
        mode = "local";
        port = 18789;
        bind = "loopback";
        trustedProxies = [
          "127.0.0.1"
          "::1"
          "192.168.10.0/24"
        ];
        auth.mode = "token"; # token from CLAWDBOT_GATEWAY_TOKEN env var
      };
      agents = {
        defaults = {
          model.primary = "anthropic/claude-sonnet-4-5";
          model.fallbacks = [
            "anthropic/claude-haiku-4-5"
            "anthropic/claude-opus-4-5"
          ];
          maxConcurrent = 4;
          subagents.maxConcurrent = 8;
          envelopeTimezone = "Europe/Berlin";
          heartbeat = {
            every = "30m";
            target = "last";
          };
          #models = {
          #  "anthropic/claude-haiku-4-5" = {
          #    alias = "haiku";
          #  };
          #  "anthropic/claude-sonnet-4-5" = {
          #    alias = "sonnet";
          #  };
          #  "anthropic/claude-opus-4-5" = {
          #    alias = "opus";
          #  };
        };
        list = [
          {
            id = "main";
            default = true;
            workspace = "${stateDir}/clawd";
          }
          {
            id = "simon";
            workspace = "${stateDir}/clawd-simon";
          }
          {
            id = "iuser";
            workspace = "${stateDir}/clawd-iuser";
          }
        ];
      };
      bindings = [
        {
          agentId = "simon";
          match = {
            channel = "signal";
            peer = {
              kind = "dm";
              id = "uuid:dcca284c-5b24-4eba-8e40-bb9649c1502c";
            };
          };
        }
        {
          agentId = "iuser";
          match = {
            channel = "signal";
            peer = {
              kind = "dm";
              id = "uuid:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx";
            };
          };
        }
      ];
      channels = {
        signal = {
          enabled = true;
          account = "+4915251840217";
          cliPath = "${pkgs.signal-cli}/bin/signal-cli";
          dmPolicy = "pairing";
          configWrites = false;
        };
      };
      plugins = {
        entries = {
          signal = {
            enabled = true;
          };
        };
      };
      commands = {
        native = "auto";
        nativeSkills = "auto";
        restart = true;
      };
      auth = {
        profiles = {
          "anthropic:claude-cli" = {
            provider = "anthropic";
            mode = "oauth";
          };
        };
      };
      messages = {
        ackReactionScope = "group-mentions";
      };
      session = {
        dmScope = "per-channel-peer";
      };
    }
  );
in
{
  environment.systemPackages = [
    clawdbot
    pkgs.claude-code
    pkgs.signal-cli
  ];

  nixfiles.nginx.vhosts.clawdbot.port = 18789;

  users.users.clawdbot = {
    isSystemUser = true;
    group = "clawdbot";
    home = "/var/lib/clawdbot";
    createHome = true;
    shell = pkgs.bash;
  };

  users.groups.clawdbot = { };

  clan.core.vars.generators.clawdbot = {
    prompts.brave-api-key = {
      description = "Brave Search API key (get free at brave.com/search/api)";
      type = "hidden";
      persist = true;
    };
    files."gateway-token".secret = true;
    files."env" = {
      secret = true;
      owner = "clawdbot";
      group = "clawdbot";
    };
    script = ''
      head -c 32 /dev/urandom | base64 | tr -d '/+=' | head -c 32 > $out/gateway-token
      {
        echo "BRAVE_API_KEY=$(cat $prompts/brave-api-key)"
        echo "CLAWDBOT_GATEWAY_TOKEN=$(cat $out/gateway-token)"
      } > $out/env
    '';
  };

  environment.sessionVariables = {
    CLAWDBOT_CONFIG_PATH = "${configFile}";
    CLAWDBOT_STATE_DIR = stateDir;
  };

  systemd.services.clawdbot = {
    description = "clawdbot AI gateway";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      User = "clawdbot";
      Group = "clawdbot";
      WorkingDirectory = stateDir;
      EnvironmentFile = config.clan.core.vars.generators.clawdbot.files."env".path;
      Environment = [
        "CLAWDBOT_CONFIG_PATH=${configFile}"
        "CLAWDBOT_STATE_DIR=${stateDir}"
        "CLAWDBOT_NIX_MODE=1"
        "OLLAMA_API_KEY=ollama-local"
      ];
      ExecStartPre = map (
        id:
        "${pkgs.bash}/bin/bash -c 'mkdir -p ${stateDir}/agents/${id}/agent && [ ! -e ${stateDir}/agents/${id}/agent/auth-profiles.json ] && ln -s ${stateDir}/agents/main/agent/auth-profiles.json ${stateDir}/agents/${id}/agent/auth-profiles.json || true'"
      ) secondaryAgents;
      ExecStart = "${clawdbot}/bin/clawdbot gateway";
      Restart = "on-failure";
      RestartSec = "10s";
    };
  };
}

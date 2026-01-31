{
  config,
  pkgs,
  inputs,
  ...
}:
let
  stateDir = "/var/lib/openclaw";
  # override to bundle docs until upstream PR #29 merges
  openclaw-gateway =
    inputs.nix-openclaw.packages.${pkgs.stdenv.hostPlatform.system}.openclaw-gateway.overrideAttrs
      (old: {
        # installPhase is a script path, run it then copy docs
        installPhase = ''
          source ${old.installPhase}
          if [ -d "$src/docs" ]; then
            cp -r "$src/docs" "$out/lib/openclaw/"
          fi
        '';
      });

  # secondary agents that share credentials with main
  secondaryAgents = [
    "simon"
    "iuser"
  ];
  configFile = pkgs.writeText "openclaw.json" (
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
            workspace = "${stateDir}/workspaces/main";
          }
          {
            id = "simon";
            workspace = "${stateDir}/workspaces/simon";
          }
          {
            id = "iuser";
            workspace = "${stateDir}/workspaces/iuser";
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
              id = "uuid:c4c7789f-f5e0-4340-bb57-ffb4e412bbd9";
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
      tools.media.audio = {
        enabled = true;
        # uses whisper-cli from PATH, auto-downloads tiny model
      };
      skills = {
        allowBundled = [
          "github"
          "clawhub"
          "weather"
        ];
        load = {
          extraDirs = [ "${stateDir}/skills" ];
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
        tts = {
          auto = "off"; # always reply with voice
          provider = "elevenlabs";
          elevenlabs = {
            voiceId = "CwhRBWXzGAHq8TQ4Fs17";
            modelId = "eleven_flash_v2_5";
          };
        };
      };
      session = {
        dmScope = "per-peer"; # per-channel-peer
      };
    }
  );
in
{
  # cli tools for manual use, rest goes to service path
  environment.systemPackages = [
    openclaw-gateway
    pkgs.claude-code
    pkgs.signal-cli
    pkgs.whisper-cpp # STT - must be in system PATH for openclaw to find
  ];

  nixfiles.nginx.vhosts.openclaw.port = 18789;

  users.users.openclaw = {
    isSystemUser = true;
    group = "openclaw";
    extraGroups = [ "shared" ];
    home = "/var/lib/openclaw";
    createHome = true;
    shell = pkgs.bashInteractive;
  };

  users.groups.openclaw = { };

  clan.core.vars.generators.openclaw = {
    prompts.brave-api-key = {
      description = "Brave Search API key (get free at brave.com/search/api)";
      type = "hidden";
      persist = true;
    };
    prompts.elevenlabs-api-key = {
      description = "ElevenLabs API key for TTS";
      type = "hidden";
      persist = true;
    };
    files."gateway-token".secret = true;
    files."env" = {
      secret = true;
      owner = "openclaw";
      group = "openclaw";
    };
    script = ''
      head -c 32 /dev/urandom | base64 | tr -d '/+=' | head -c 32 > $out/gateway-token
      {
        echo "BRAVE_API_KEY=$(cat $prompts/brave-api-key)"
        echo "ELEVENLABS_API_KEY=$(cat $prompts/elevenlabs-api-key)"
        echo "CLAWDBOT_GATEWAY_TOKEN=$(cat $out/gateway-token)"
        echo "OPENCLAW_GATEWAY_TOKEN=$(cat $out/gateway-token)"
      } > $out/env
    '';
  };

  environment.sessionVariables = {
    CLAWDBOT_CONFIG_PATH = "${configFile}";
    CLAWDBOT_STATE_DIR = stateDir;

    OPENCLAW_CONFIG_PATH = "${configFile}";
    OPENCLAW_STATE_DIR = stateDir;
  };

  systemd.services.openclaw = {
    description = "openclaw AI gateway";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    # tools available to the service (skills, document processing, etc.)
    path = with pkgs; [
      gh # github skill
      libreoffice
      ffmpeg
      imagemagick
      tesseract
      zip
      unzip
      (python3.withPackages (ps: [ ps.python-pptx ]))
      whisper-cpp # STT for voice messages
    ];

    serviceConfig = {
      Type = "simple";
      User = "openclaw";
      Group = "openclaw";
      WorkingDirectory = stateDir;
      StateDirectory = "openclaw";
      RuntimeDirectory = "openclaw";
      EnvironmentFile = config.clan.core.vars.generators.openclaw.files."env".path;
      Environment = [
        "CLAWDBOT_CONFIG_PATH=${configFile}"
        "CLAWDBOT_STATE_DIR=${stateDir}"
        "CLAWDBOT_NIX_MODE=1"

        "OPENCLAW_CONFIG_PATH=${configFile}"
        "OPENCLAW_STATE_DIR=${stateDir}"
        "OPENCLAW_NIX_MODE=1"

        "OLLAMA_API_KEY=ollama-local"
        "XDG_RUNTIME_DIR=/run/openclaw"
        "WHISPER_CPP_MODEL=${stateDir}/ggml-base.bin"
      ];
      ExecStartPre = [
        "${pkgs.coreutils}/bin/mkdir -p ${stateDir}/workspaces/main ${stateDir}/workspaces/simon ${stateDir}/workspaces/iuser ${stateDir}/agents/main/agent"
      ]
      ++ map (
        id:
        "${pkgs.bash}/bin/bash -c 'mkdir -p ${stateDir}/agents/${id}/agent && [ ! -L ${stateDir}/agents/${id}/agent/auth-profiles.json ] && rm -f ${stateDir}/agents/${id}/agent/auth-profiles.json; ln -sf ${stateDir}/agents/main/agent/auth-profiles.json ${stateDir}/agents/${id}/agent/auth-profiles.json'"
      ) secondaryAgents;
      ExecStart = "${openclaw-gateway}/bin/openclaw gateway";
      Restart = "always";
      RestartSec = "10s";

      # Hardening options
      ProtectHome = true;
      ProtectSystem = "strict";
      PrivateTmp = true;
      PrivateDevices = true;
      NoNewPrivileges = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectKernelLogs = true;
      ProtectControlGroups = true;
      ProtectProc = "invisible";
      ProcSubset = "pid";
      ProtectHostname = true;
      ProtectClock = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      RemoveIPC = true;
      LockPersonality = true;

      # Filesystem access
      ReadWritePaths = [ stateDir ];

      # Capability restrictions
      CapabilityBoundingSet = "";
      AmbientCapabilities = "";

      # Network restrictions (gateway needs network)
      # AF_NETLINK required for os.networkInterfaces() in Node.js
      RestrictAddressFamilies = [
        "AF_INET"
        "AF_INET6"
        "AF_UNIX"
        "AF_NETLINK"
      ];
      IPAddressDeny = "multicast";

      # System call filtering
      # Only @system-service - Node.js with native modules needs more syscalls
      # Security comes from capability restrictions and namespace isolation instead
      SystemCallFilter = [ "@system-service" ];
      SystemCallArchitectures = "native";

      # Memory protection
      # Note: MemoryDenyWriteExecute may break Node.js JIT - disabled for now
      # MemoryDenyWriteExecute = true;

      RestrictNamespaces = true;
      UMask = "0027";
    };
  };
}

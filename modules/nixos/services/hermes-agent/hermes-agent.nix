{ inputs, ... }:
{
  # hermes itself, nothing about where it runs. import it on a host to run it
  # there, or list it in an agent-vm to run it sealed off — see
  # modules/nixos/virtualization/agent-vm.nix.
  flake.modules.nixos.hermesAgent =
    {
      config,
      agentVm ? null,
      flake-self,
      lib,
      pkgs,
      ...
    }:
    let
      stateDir = config.services.hermes-agent.stateDir;
      dashboardHost = "127.0.0.1";
    in
    {
      imports = [ inputs.hermes-agent.nixosModules.default ];

      services.hermes-agent = {
        enable = true;
        addToSystemPackages = true;

        extraPackages = [
          pkgs.agent-browser
          pkgs.local.blogwatcher-cli
          pkgs.chromium
          pkgs.curl
          pkgs.himalaya
        ];

        settings = {
          timezone = "Europe/Berlin";
          display.personality = "none";

          terminal.backend = "local";

          tts.provider = "piper";

          stt = {
            provider = "local";
            local.model = "base";
          };

          skills.external_dirs = [
            "${config.services.hermes-agent.package}/share/hermes-agent/optional-skills/devops/watchers"
          ];

          providers.local = {
            name = "Local";
            api = "https://llama-cpp.${flake-self.domains.local}/v1";
            api_key = "no-key-required";
            default_model = "qwen3.6-35b-a3b-mtp";
            context_length = 131072;
          };

          # local sqlite fact store next to the built-in MEMORY.md, which keeps
          # loading; the only provider with no api-key path and no llm calls
          memory.provider = "holographic";

          # summarise old turns instead of hitting the context wall
          compression.enabled = true;

          # own searxng instead of the paid search apis hermes defaults to
          web.search_backend = "searxng";

          # standalone plugins are opt-in; bundled platform/backend ones
          # (matrix, searxng) auto-load and are not affected by this list
          plugins.enabled = [
            "disk-cleanup"
            "hermes-achievements"
          ];

          model = {
            # the only alias llama-cpp preloads; models-max = 1, so naming any
            # other one costs a model swap on the first request
            default = "qwen3.6-35b-a3b-mtp";
            provider = "local";
            context_length = 131072;
          };
        };

        # the matrix domain is neither domains.local nor domains.public: mxids
        # live on fosskar.de, which delegates its client api to matrix.fosskar.eu
        environment = {
          SEARXNG_URL = "https://search.${flake-self.domains.local}/";
          SIGNAL_HTTP_URL = "http://127.0.0.1:18081";
          SIGNAL_ALLOW_ALL_USERS = "false";

          MATRIX_HOMESERVER = "https://matrix.fosskar.eu";
          MATRIX_USER_ID = "@hermes:fosskar.de";
          MATRIX_DEVICE_ID = "HERMES_BOT";
          MATRIX_ALLOWED_USERS = "@fosskar:fosskar.de";
          # fail closed rather than silently falling back to plaintext when
          # crypto cannot initialise. MATRIX_ENCRYPTION is the deprecated alias
          MATRIX_E2EE_MODE = "required";
        };
      };

      system.activationScripts.hermes-agent-soul = lib.stringAfter [ "hermes-agent-setup" ] ''
        ${pkgs.coreutils}/bin/install \
          -o ${config.services.hermes-agent.user} \
          -g ${config.services.hermes-agent.group} \
          -m 0660 \
          ${./SOUL.md} \
          ${stateDir}/.hermes/SOUL.md
      '';

      # -i, not -H: a login shell resets PATH to hermes' own profile. with the
      # caller's PATH the agent's packages are not found and unreadable /root
      # entries turn "command not found" into EACCES
      environment.shellAliases.hermes = "sudo -iu hermes hermes";

      systemd.services.hermes-dashboard = {
        description = "Hermes Agent dashboard";
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        unitConfig.RequiresMountsFor = [ "/run/agent-secrets" ];
        environment = {
          HOME = stateDir;
          HERMES_HOME = "${stateDir}/.hermes";
          HERMES_MANAGED = "true";
        };
        serviceConfig = {
          User = "hermes";
          Group = "hermes";
          WorkingDirectory = config.services.hermes-agent.workingDirectory;
          LoadCredential = "dashboard-token:/run/agent-secrets/hermes-dashboard-token";
          ExecStart = pkgs.writeShellScript "hermes-dashboard-start" ''
            export HERMES_DASHBOARD_SESSION_TOKEN
            HERMES_DASHBOARD_SESSION_TOKEN="$(cat "$CREDENTIALS_DIRECTORY/dashboard-token")"
            exec ${config.services.hermes-agent.package}/bin/hermes dashboard \
              --no-open --host ${dashboardHost} --port 9119
          '';
          Restart = "always";
          RestartSec = 5;
          UMask = "0007";
        };
      };

      systemd.services.hermes-dashboard-proxy = lib.mkIf (agentVm != null) {
        description = "Hermes dashboard vsock proxy";
        wantedBy = [ "multi-user.target" ];
        after = [ "hermes-dashboard.service" ];
        serviceConfig = {
          ExecStart = "${pkgs.socat}/bin/socat VSOCK-LISTEN:9119,fork TCP:127.0.0.1:9119";
          Restart = "always";
          RestartSec = 5;
        };
      };

      # what upstream's ubuntu container mode exists for: somewhere the agent
      # can pip/npm install at runtime
      systemd.tmpfiles.rules = [
        "d ${stateDir}/venv 0750 hermes hermes - -"
        "d ${stateDir}/npm 0750 hermes hermes - -"
      ];

      systemd.services.hermes-venv = {
        description = "writable pip venv for the agent";
        wantedBy = [ "hermes-agent.service" ];
        before = [ "hermes-agent.service" ];
        unitConfig.ConditionPathExists = "!${stateDir}/venv/bin/python";
        serviceConfig = {
          Type = "oneshot";
          User = "hermes";
          RemainAfterExit = true;
        };
        script = "${pkgs.python3}/bin/python3 -m venv ${stateDir}/venv";
      };

      users.users.hermes.packages = [
        pkgs.nodejs
        pkgs.python3
      ];

      environment.variables = {
        NPM_CONFIG_PREFIX = "${stateDir}/npm";
        VIRTUAL_ENV = "${stateDir}/venv";
      };
    };
}

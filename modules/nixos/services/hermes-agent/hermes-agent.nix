{ inputs, ... }:
{
  # the engine plus this homelab's agent policy: model, voice, search backend,
  # plugins. identity, channels and skill selection come from the clan service
  # composing this with its channel aspects
  flake.modules.nixos.hermesAgent =
    {
      config,
      agentSandbox,
      flake-self,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.hermes-agent;
      inherit (cfg) stateDir;

      rtk = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.rtk;

      # generated, not vendored, so the plugin tracks the pinned rtk. `rtk
      # rewrite` is the single source of truth; the plugin only bridges
      # hermes' pre_tool_call payload to it
      rtkPlugin = pkgs.runCommand "rtk-hermes-plugin" { nativeBuildInputs = [ rtk ]; } ''
        export HOME="$PWD"
        rtk init -g --agent hermes
        cp -r "$HOME/.hermes/plugins/rtk-rewrite" "$out"
      '';

      defaults = {
        timezone = "Europe/Berlin";
        display.personality = "none";
        terminal.backend = "local";
        tts.provider = "piper";
        stt = {
          provider = "local";
          local.model = "base";
        };
        # own searxng instead of the paid search apis hermes defaults to
        web.search_backend = "searxng";
        # standalone plugins are opt-in; bundled platform/backend ones
        # (matrix, searxng) auto-load and are not affected by this list
        plugins.enabled = [
          "disk-cleanup"
          "hermes-achievements"
          "rtk-rewrite"
        ];
        # local sqlite fact store next to the built-in MEMORY.md, which keeps
        # loading; the only provider with no api-key path and no llm calls
        memory.provider = "holographic";
        # summarise old turns instead of hitting the context wall
        compression.enabled = true;
      }
      // lib.optionalAttrs cfg.localProvider.enable {
        providers.local = {
          name = "Local";
          api = "https://llama-cpp.${flake-self.domains.local}/v1";
          api_key = "no-key-required";
          default_model = "qwen3.6-35b-a3b-mtp";
          context_length = 98304;
        };
        model = {
          default = "qwen3.6-35b-a3b-mtp";
          provider = "local";
          context_length = 98304;
        };
      };
    in
    {
      imports = [ inputs.hermes-agent.nixosModules.default ];

      options.services.hermes-agent = {
        localProvider.enable = lib.mkEnableOption "the homelab llama-cpp endpoint as the default model provider";

        soul = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = "SOUL.md to install read-only on every activation.";
        };

        skillDirs = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "directories handed to the agent as skills.external_dirs.";
        };

        overrides = lib.mkOption {
          type = lib.types.attrsOf lib.types.raw;
          default = { };
          description = ''
            merged over this module's settings defaults. upstream's settings type
            deep-merges definitions but ignores mkDefault/mkForce priorities, so
            precedence is spelled out here rather than left to module order.
          '';
        };
      };

      config = {
        services.hermes-agent = {
          enable = true;
          addToSystemPackages = true;

          extraPackages = [
            rtk
            pkgs.agent-browser
            pkgs.local.blogwatcher-cli
            pkgs.chromium
            pkgs.curl
            pkgs.gh
            pkgs.himalaya
          ];

          # skillDirs comes from the deployment's skill selection, so it wins
          # over overrides
          settings = lib.recursiveUpdate (lib.recursiveUpdate defaults cfg.overrides) (
            lib.optionalAttrs (cfg.skillDirs != [ ]) { skills.external_dirs = cfg.skillDirs; }
          );

          environment.SEARXNG_URL = "https://search.${flake-self.domains.local}/";
        };

        # reinstalled on every activation: the soul is declarative, agent edits
        # do not survive
        system.activationScripts.hermes-agent-soul = lib.mkIf (cfg.soul != null) (
          lib.stringAfter [ "hermes-agent-setup" ] ''
            ${pkgs.coreutils}/bin/install \
              -o ${cfg.user} \
              -g ${cfg.group} \
              -m 0444 \
              ${cfg.soul} \
              ${stateDir}/.hermes/SOUL.md
          ''
        );

        # user plugins live under HERMES_HOME and are gated by plugins.enabled
        # above; both halves are required or the hook silently never registers
        system.activationScripts.hermes-agent-rtk = lib.stringAfter [ "hermes-agent-setup" ] ''
          ${pkgs.coreutils}/bin/install \
            -d \
            -o ${cfg.user} \
            -g ${cfg.group} \
            -m 0755 \
            ${stateDir}/.hermes/plugins/rtk-rewrite
          ${pkgs.coreutils}/bin/install \
            -o ${cfg.user} \
            -g ${cfg.group} \
            -m 0444 \
            ${rtkPlugin}/plugin.yaml \
            ${rtkPlugin}/__init__.py \
            ${stateDir}/.hermes/plugins/rtk-rewrite/
        '';

        # -i, not -H: a login shell resets PATH to hermes' own profile. with the
        # caller's PATH the agent's packages are not found and unreadable /root
        # entries turn "command not found" into EACCES
        environment.shellAliases.hermes = "sudo -iu hermes env NPM_CONFIG_PREFIX=${stateDir}/npm VIRTUAL_ENV=${stateDir}/venv hermes";

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
            NPM_CONFIG_PREFIX = "${stateDir}/npm";
            VIRTUAL_ENV = "${stateDir}/venv";
          };
          serviceConfig = {
            User = "hermes";
            Group = "hermes";
            WorkingDirectory = cfg.workingDirectory;
            LoadCredential = "dashboard-token:/run/agent-secrets/hermes-dashboard-token";
            ExecStart = pkgs.writeShellScript "hermes-dashboard-start" ''
              export HERMES_DASHBOARD_SESSION_TOKEN
              HERMES_DASHBOARD_SESSION_TOKEN="$(cat "$CREDENTIALS_DIRECTORY/dashboard-token")"
              exec ${cfg.package}/bin/hermes dashboard \
                --no-open --host ${agentSandbox.bindAddress} --port 9119
            '';
            Restart = "always";
            RestartSec = 5;
            UMask = "0007";
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
          serviceConfig = {
            Type = "oneshot";
            User = "hermes";
            RemainAfterExit = true;
          };
          # the venv symlinks its interpreter from the store; after a python
          # bump the old path is gone and site-packages target the wrong abi,
          # so rebuild instead of repairing in place
          script = ''
            want="$(readlink -f ${pkgs.python3}/bin/python3)"
            have="$(readlink -f ${stateDir}/venv/bin/python 2>/dev/null || true)"
            if [ "$have" != "$want" ]; then
              rm -rf ${stateDir}/venv
              install -d -m 0750 ${stateDir}/venv
              ${pkgs.python3}/bin/python3 -m venv ${stateDir}/venv
            fi
          '';
        };

        users.users.hermes.packages = [
          pkgs.nodejs
          pkgs.python3
        ];

        # NPM_CONFIG_PREFIX and VIRTUAL_ENV only tell the installers where to
        # write; without their bin dirs on PATH the agent cannot run what it
        # installed, not even pip itself
        systemd.services.hermes-agent = {
          environment = {
            NPM_CONFIG_PREFIX = "${stateDir}/npm";
            VIRTUAL_ENV = "${stateDir}/venv";
          };
          path = lib.mkBefore [
            "${stateDir}/venv"
            "${stateDir}/npm"
          ];
        };
      };
    };
}

{ inputs, ... }:
{
  # the engine plus this homelab's agent policy: model, voice, search backend,
  # plugins. identity, channels and skill selection come from the clan service
  # composing this with its channel aspects
  flake.modules.nixos.hermesAgent =
    {
      config,
      flake-self,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.hermes-agent;
      inherit (cfg) stateDir;

      rtk = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.rtk;

      # the preset id /v1/models reports, not its alias: hermes lists the
      # configured name next to the discovered id, so an alias shows the one
      # model twice in the picker
      localModel = "unsloth/Qwen3.6-35B-A3B-MTP-GGUF:Q4_K_XL";

      # generated, not vendored, so the plugin tracks the pinned rtk. `rtk
      # rewrite` is the single source of truth; the plugin only bridges
      # hermes' pre_tool_call payload to it
      rtkPlugin = pkgs.runCommand "rtk-rewrite" { nativeBuildInputs = [ rtk ]; } ''
        export HOME="$PWD"
        rtk init -g --agent hermes
        cp -r "$HOME/.hermes/plugins/rtk-rewrite" "$out"
      '';

      # top-level scalar of a flat yaml file; enough for catalog entries and
      # plugin manifests, including the json-styled ones (hermes-terminal)
      yamlField =
        file: key:
        let
          matches = lib.filter (m: m != null) (
            map (line: builtins.match " *\"?${key}\"?: *\"?([^\",]*)\"?,? *" line) (
              lib.splitString "\n" (builtins.readFile file)
            )
          );
        in
        if matches == [ ] then "" else lib.head (lib.head matches);

      # the catalog entry is the pin: repo + 40-hex sha, reviewed upstream and
      # bumped with the hermes-agent input. a full rev keeps fetchGit pure.
      # plugins.enabled matches the manifest name, which need not equal the
      # catalog key (hermes-memory-wiki ships as memory-wiki)
      catalogPlugin =
        name:
        let
          entry = "${inputs.hermes-agent}/plugin-catalog/${name}.yaml";
          src = fetchGit {
            url = yamlField entry "repo";
            rev = yamlField entry "sha";
            allRefs = true;
          };
          root = "${src}/${yamlField entry "subdir"}";
        in
        {
          package = pkgs.runCommand name { } "cp -r ${root} $out";
          pluginName = yamlField "${root}/plugin.yaml" "name";
        };

      catalogPlugins = map catalogPlugin cfg.catalogPlugins;

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
        ]
        ++ map (plugin: plugin.pluginName) catalogPlugins;
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
          default_model = localModel;
          context_length = null;
        };
        # null context_length: hermes reads llama.cpp's per-slot meta.n_ctx from
        # /v1/models, so the window follows the llamaCpp module. the explicit null
        # overrides stale pins left in the writable HERMES_HOME/config.yaml
        model = {
          default = localModel;
          provider = "local";
          context_length = null;
        };
      };
    in
    {
      imports = [ inputs.hermes-agent.nixosModules.default ];

      options.services.hermes-agent = {
        localProvider.enable = lib.mkEnableOption "the homelab llama-cpp endpoint as the default model provider";

        dashboard.enable = lib.mkEnableOption "the Hermes dashboard";

        dashboardTokenFile = lib.mkOption {
          type = lib.types.str;
          description = "runtime file containing the dashboard session token.";
        };

        soul = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = "SOUL.md to install read-only on every activation.";
        };

        catalogPlugins = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "entries of hermes' plugin-catalog/ to install and enable, by catalog name.";
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

          # symlinked into HERMES_HOME/plugins and gated by plugins.enabled
          # above; both halves are required or the hook silently never registers
          extraPlugins = [ rtkPlugin ] ++ map (plugin: plugin.package) catalogPlugins;

          extraPackages = [
            rtk
            # lazy optional-dep installs into HERMES_LAZY_INSTALL_TARGET go
            # through uv; without it the pip tier fails on the store env
            pkgs.uv
            pkgs.agent-browser
            pkgs.local.blogwatcher-cli
            pkgs.chromium
            pkgs.curl
            pkgs.gh
            pkgs.gitMinimal
            pkgs.himalaya
          ];

          # skillDirs comes from the deployment's skill selection, so it wins
          # over overrides
          settings = lib.recursiveUpdate (lib.recursiveUpdate defaults cfg.overrides) (
            lib.optionalAttrs (cfg.skillDirs != [ ]) { skills.external_dirs = cfg.skillDirs; }
          );

          environment.SEARXNG_URL = "https://search.${flake-self.domains.local}/";

        };

        # managed scope: the declared settings are pinned per leaf from
        # /etc/hermes, and everything else in HERMES_HOME/config.yaml stays
        # writable by the agent and the ui. HERMES_MANAGED=false below lifts
        # upstream's blanket refusal of config writes; hermes update stays
        # refused by its own /nix/store check
        environment.etc."hermes/config.yaml".source =
          (pkgs.formats.yaml { }).generate "hermes-managed-config.yaml"
            config.services.hermes-agent.settings;

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

        # -i, not -H: a login shell resets PATH to hermes' own profile. with the
        # caller's PATH the agent's packages are not found and unreadable /root
        # entries turn "command not found" into EACCES
        environment.shellAliases.hermes = "sudo -iu hermes env HERMES_MANAGED=false HERMES_LAZY_INSTALL_TARGET=${stateDir}/lazy-deps NPM_CONFIG_PREFIX=${stateDir}/npm VIRTUAL_ENV=${stateDir}/venv hermes";

        systemd.services.hermes-dashboard = lib.mkIf cfg.dashboard.enable {
          description = "Hermes Agent dashboard";
          path = config.systemd.services.hermes-agent.path;
          wantedBy = [ "multi-user.target" ];
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          environment = {
            HOME = stateDir;
            HERMES_HOME = "${stateDir}/.hermes";
            HERMES_MANAGED = "false";
            HERMES_LAZY_INSTALL_TARGET = "${stateDir}/lazy-deps";
            NPM_CONFIG_PREFIX = "${stateDir}/npm";
            VIRTUAL_ENV = "${stateDir}/venv";
          };
          serviceConfig = {
            User = "hermes";
            Group = "hermes";
            WorkingDirectory = cfg.workingDirectory;
            LoadCredential = "dashboard-token:${cfg.dashboardTokenFile}";
            ExecStart = pkgs.writeShellScript "hermes-dashboard-start" ''
              export HERMES_DASHBOARD_SESSION_TOKEN
              HERMES_DASHBOARD_SESSION_TOKEN="$(cat "$CREDENTIALS_DIRECTORY/dashboard-token")"
              exec ${cfg.package}/bin/hermes dashboard \
                --no-open --host 127.0.0.1 --port 9119
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
          "d ${stateDir}/lazy-deps 0750 hermes hermes - -"
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

        users.users.hermes.linger = true;
        users.users.hermes.packages = [
          pkgs.nodejs
          pkgs.python3
        ];

        # NPM_CONFIG_PREFIX and VIRTUAL_ENV only tell the installers where to
        # write; without their bin dirs on PATH the agent cannot run what it
        # installed, not even pip itself
        systemd.services.hermes-agent = {
          serviceConfig.PAMName = "login";
          environment = {
            # system users otherwise get a session that does not start a user manager.
            XDG_SESSION_CLASS = "background";
            HERMES_MANAGED = lib.mkForce "false";
            HERMES_LAZY_INSTALL_TARGET = "${stateDir}/lazy-deps";
            NPM_CONFIG_PREFIX = "${stateDir}/npm";
            VIRTUAL_ENV = "${stateDir}/venv";
            PYTHONPATH = toString (
              pkgs.linkFarm "hermes-state-registry-fix" [
                {
                  name = "hermes_state_registry.py";
                  path = "${inputs.hermes-agent}/hermes_state_registry.py";
                }
              ]
            );
          };
          path = lib.mkBefore [
            "${stateDir}/venv"
            "${stateDir}/npm"
          ];
        };
      };
    };
}

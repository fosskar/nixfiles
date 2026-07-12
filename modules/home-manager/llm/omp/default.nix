_: {
  flake.modules.homeManager.llm =
    {
      inputs,
      pkgs,
      lib,
      ...
    }:
    let
      extensionFiles = removeAttrs (builtins.readDir ../extensions) [ "pi-to-PI.ts" ];
      extensionEntries = lib.mapAttrs' (
        name: _: lib.nameValuePair ".omp/agent/extensions/${name}" { source = ../extensions/${name}; }
      ) extensionFiles;

      # declarative omp settings overlay: non-default values only (schema
      # defaults omitted). merged on top of existing local config.yml (or
      # deployed 1:1 if none exists).
      ompSettings = {
        setupVersion = 1;
        theme.dark = "custom";
        statusLine = {
          transparent = true;
          # thinking level as glyph-only model icon, no " · <level>" tail
          compactThinkingLevel = true;
          # default preset + usage (sub quota %); custom preset required:
          # named presets ignore leftSegments/rightSegments
          preset = "custom";
          leftSegments = [
            "model"
            "mode"
            "path"
            "git"
            "pr"
            "usage"
          ];
          rightSegments = [ "session_name" ];
          segmentOptions = {
            model.showThinkingLevel = true;
            path = {
              abbreviate = true;
              maxLength = 40;
              stripWorkPrefix = true;
            };
            git = {
              # colocated jj keeps git HEAD detached -> branch renders literal
              # "detached" (oh-my-pi#3582); hide branch, keep dirty counters
              showBranch = false;
              showStaged = true;
              showUnstaged = true;
              showUntracked = true;
            };
          };
        };
        hideThinkingBlock = true;
        showTokenUsage = false;
        display.showTokenUsage = false;
        personality = "pragmatic";
        advisor.enabled = true;
        symbolPreset = "nerd";
        collapseChangelog = true;
        followUpMode = "all";
        providers.webSearch = "anthropic";
        defaultThinkingLevel = "auto";
        stt.enabled = false;
        startup = {
          quiet = true;
          setupWizard = false;
          checkUpdate = false;
        };
        autolearn.enabled = true;
        features.unexpectedStopDetection = true;
        compaction.handoffSaveToDisk = true;
        memory.backend = "mnemopi";
        mnemopi.scoping = "per-project-tagged";
        mnemopi.polyphonicRecall = true;
        lsp.formatOnWrite = true;
        github.enabled = true;
        secrets.enabled = true;
        vault.enabled = true;
      };
      # json is valid yaml; yq merges it into config.yml
      ompSettingsFile = pkgs.writeText "omp-settings-overlay.json" (builtins.toJSON ompSettings);
    in
    {
      home.packages = [
        inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.omp
      ];

      home.file = {
        ".omp/agent/AGENTS.md".source = ../AGENTS.md;
      }
      // extensionEntries;

      # deploy or merge omp config.yml; keep it a real writable file since omp
      # persists settings changes back to it at runtime
      home.activation.ompSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        config="$HOME/.omp/agent/config.yml"
        mkdir -p "$(dirname "$config")"
        if [ -f "$config" ]; then
          # merge: nix keys win, local-only keys preserved
          ${pkgs.yq-go}/bin/yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' \
            "$config" "${ompSettingsFile}" > "$config.tmp"
          mv "$config.tmp" "$config"
        else
          # no existing file: deploy 1:1
          ${pkgs.yq-go}/bin/yq -P '.' "${ompSettingsFile}" > "$config"
          chmod 644 "$config"
        fi
      '';
    };
}

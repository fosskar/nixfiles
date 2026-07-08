{
  flake.modules.homeManager.herdr =
    {
      inputs,
      pkgs,
      lib,
      ...
    }:
    let
      # declarative herdr settings overlay: non-default values only. merged on
      # top of existing local config.toml (or deployed 1:1 if none exists).
      herdrSettings = {
        onboarding = false;
        update.version_check = false;
        # note: yq merge replaces arrays, so keys.command is nix-owned as a whole
        keys.command = [
          {
            key = "prefix+f";
            type = "shell";
            command = "herdr plugin action invoke open-file-viewer --plugin herdr-file-viewer";
          }
          {
            key = "prefix+shift+f";
            type = "shell";
            command = "herdr plugin action invoke open-file-viewer-tab --plugin herdr-file-viewer";
          }
        ];
      };
      herdrSettingsFile = (pkgs.formats.toml { }).generate "herdr-settings-overlay.toml" herdrSettings;

      herdrBin = "${inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.herdr}/bin/herdr";

      # plugin id (from herdr-plugin.toml) -> github install shorthand
      herdrPlugins = {
        "herdr-file-viewer" = "smarzban/herdr-file-viewer";
        "nathanflurry.jj-workspace" = "NathanFlurry/herdr-plugin-jj-workspace";
      };

      # git for the source clone; rust toolchain for plugins built from source
      # (e.g. jj-workspace has no prebuilt binary)
      pluginInstallPath = lib.makeBinPath [
        pkgs.git
        pkgs.cargo
        pkgs.rustc
        pkgs.gcc
      ];
    in
    {
      home.packages = [
        inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.herdr
      ];

      # deploy or merge herdr config.toml; keep it a real writable file since
      # herdr persists settings changes back to it at runtime
      home.activation.herdrSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        config="$HOME/.config/herdr/config.toml"
        mkdir -p "$(dirname "$config")"
        if [ -f "$config" ]; then
          # merge: nix keys win, local-only keys preserved
          ${pkgs.yq-go}/bin/yq eval-all -p toml -o toml 'select(fileIndex == 0) * select(fileIndex == 1)' \
            "$config" "${herdrSettingsFile}" > "$config.tmp"
          mv "$config.tmp" "$config"
        else
          # no existing file: deploy 1:1
          ${pkgs.yq-go}/bin/yq -p toml -o toml '.' "${herdrSettingsFile}" > "$config"
          chmod 644 "$config"
        fi
      '';

      # install missing plugins via herdr's own installer; needs the running
      # herdr server socket, so skip with a warning when it is unreachable
      home.activation.herdrPlugins = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if installed=$(${herdrBin} plugin list --json 2>/dev/null); then
          ${lib.concatStrings (
            lib.mapAttrsToList (id: source: ''
              if ! printf '%s' "$installed" | ${pkgs.jq}/bin/jq -e '.result.plugins[] | select(.plugin_id == "${id}")' > /dev/null; then
              run PATH="${pluginInstallPath}:$PATH" ${herdrBin} plugin install ${source} --yes
              fi
            '') herdrPlugins
          )}
        else
          warnEcho "herdr server not reachable; skipping plugin install (${lib.concatStringsSep ", " (lib.attrValues herdrPlugins)})"
        fi
      '';
    };
}

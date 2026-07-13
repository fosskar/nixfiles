{
  flake.modules.homeManager.herdr =
    {
      inputs,
      pkgs,
      lib,
      ...
    }:
    let
      # full declarative config: nix owns config.toml (read-only symlink);
      # runtime settings changes in herdr do not persist across switches
      herdrSettings = {
        onboarding = false;
        update.version_check = false;
        theme.name = "vesper";
        ui.toast.delivery = "herdr";
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
          {
            key = "prefix+a";
            type = "plugin_action";
            command = "nathanflurry.jj-workspace.new-tab";
            description = "new jj workspace (in tab)";
          }
          {
            key = "prefix+shift+a";
            type = "plugin_action";
            command = "nathanflurry.jj-workspace.new";
            description = "new jj workspace";
          }
          {
            key = "prefix+d";
            type = "plugin_action";
            command = "nathanflurry.jj-workspace.remove";
            description = "remove jj workspace";
          }
          {
            key = "prefix+up";
            type = "plugin_action";
            command = "cloudmanic.herdr-plus.projects";
            description = "herdr-plus: projects";
          }
          {
            key = "prefix+down";
            type = "plugin_action";
            command = "cloudmanic.herdr-plus.quick-actions";
            description = "herdr-plus: quick actions";
          }
          {
            key = "prefix+r";
            type = "plugin_action";
            command = "persiyanov.reviewr.toggle";
            description = "reviewr: toggle sidebar";
          }
        ];
      };

      herdrPackage = inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.herdr;
      herdrBin = lib.getExe herdrPackage;

      # plugin id (from herdr-plugin.toml) -> github install shorthand
      herdrPlugins = {
        "herdr-file-viewer" = "smarzban/herdr-file-viewer";
        "nathanflurry.jj-workspace" = "NathanFlurry/herdr-plugin-jj-workspace";
        "cloudmanic.herdr-plus" = "cloudmanic/herdr-plus";
        "persiyanov.reviewr" = "persiyanov/herdr-reviewr";
        "herdr-remote.relay" = "dcolinmorgan/herdr-remote";
      };

      # herdr-plus project templates: one file = one entry in the projects
      # fuzzy picker (prefix+up); opening one builds the whole workspace with
      # all tabs/panes/startup commands. tabs open in list order; a tab
      # without command is an empty shell.
      herdrPlusProjects = {
        nixfiles = {
          name = "nixfiles";
          description = "nixos/clan config monorepo";
          working_dir = "~/Projects/nixfiles";
          tabs = [
            {
              name = "agent";
              command = "omp";
            }
            { name = "shell"; }
          ];
        };
      };

      # git for the source clone; rust/go toolchains for plugins built from
      # source (jj-workspace: cargo; herdr-plus: go — else its build.sh
      # downloads a prebuilt binary); curl for reviewr's release download
      pluginInstallPath = lib.makeBinPath [
        pkgs.git
        pkgs.cargo
        pkgs.rustc
        pkgs.gcc
        pkgs.go
        pkgs.curl
      ];
    in
    {
      programs.herdr = {
        enable = true;
        package = herdrPackage;
        settings = herdrSettings;
      };

      # attach to the remote workspace host with server-side keybindings
      home.shellAliases.herdr-workspace = "herdr --remote workspace --remote-keybindings server";

      xdg.configFile =
        # deploy herdr-plus project templates into the plugin's config dir
        lib.mapAttrs' (
          fileName: project:
          lib.nameValuePair "herdr/plugins/config/cloudmanic.herdr-plus/projects/${fileName}.toml" {
            source = (pkgs.formats.toml { }).generate "herdr-plus-project-${fileName}.toml" project;
          }
        ) herdrPlusProjects
        // {
          # running server keeps its loaded keymap; pick up new config on switch
          "herdr/config.toml".onChange = ''
            ${herdrBin} server reload-config > /dev/null 2>&1 || true
          '';
        };

      # install missing plugins via herdr's own installer; needs the running
      # herdr server socket, so skip with a warning when it is unreachable.
      # installs are best-effort: upstream tags a release needing a newer
      # toolchain than nixpkgs ships => build fails; that must not abort the
      # whole home-manager generation
      home.activation.herdrPlugins = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if installed=$(${herdrBin} plugin list --json 2>/dev/null); then
          ${lib.concatStrings (
            lib.mapAttrsToList (id: source: ''
              if ! printf '%s' "$installed" | ${pkgs.jq}/bin/jq -e '.result.plugins[] | select(.plugin_id == "${id}")' > /dev/null; then
              run env PATH="${pluginInstallPath}:$PATH" ${herdrBin} plugin install ${source} --yes \
                || warnEcho "herdr plugin install ${source} failed; continuing"
              fi
            '') herdrPlugins
          )}
        else
          warnEcho "herdr server not reachable; skipping plugin install (${lib.concatStringsSep ", " (lib.attrValues herdrPlugins)})"
        fi
      '';
    };
}

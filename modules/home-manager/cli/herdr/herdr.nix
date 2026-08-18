{
  flake.modules.homeManager.herdr =
    {
      inputs,
      config,
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
        ui.status_indicators = "symbols";
        ui.prompt_new_tab_name = false;
        worktrees.directory = "~/.herdr/worktrees";
        keys.command = [
          {
            key = "prefix+shift+f";
            type = "plugin_action";
            command = "jhochenbaum.hunkdiff.review";
            description = "hunk: review changes";
          }
          {
            key = "prefix+shift+s";
            type = "plugin_action";
            command = "jhochenbaum.hunkdiff.send-review";
            description = "hunk: send review to agent";
          }
          {
            key = "prefix+shift+c";
            type = "plugin_action";
            command = "jhochenbaum.hunkdiff.review:commit";
            description = "hunk: review the last commit";
          }
          {
            key = "prefix+shift+a";
            type = "plugin_action";
            command = "jhochenbaum.hunkdiff.review:staged";
            description = "hunk: review staged changes";
          }
          {
            key = "prefix+p";
            type = "plugin_action";
            command = "jt.command-palette.open";
            description = "Command palette";
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
        ];
      };

      herdrPackage = inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.herdr;
      herdrBin = lib.getExe herdrPackage;

      # plugin id (from herdr-plugin.toml) -> pinned github install
      herdrPlugins = {
        "jhochenbaum.hunkdiff" = {
          source = "jhochenbaum/herdr-hunk-diff";
          rev = "6810ab31b34ec28eb302603846bc4339e7063655";
        };
        "jt.command-palette" = {
          source = "JanTvrdik/herdr-command-palette";
          rev = "eab940018c2135ac23718efa11e23e9dddcd2a75";
        };
        "cloudmanic.herdr-plus" = {
          source = "cloudmanic/herdr-plus";
          rev = "a9aca9da3ca6d7406f3d878a1df1c1b9775e2723";
        };
      }
      # event pusher for the relay (herdr-remote.nix); only useful on a relay host
      // lib.optionalAttrs config.programs.herdr.remote.enable {
        "herdr-remote.relay" = {
          source = "dcolinmorgan/herdr-remote";
          rev = "9bdfe06bf5694072f4437c07d16fe7d769640c61";
        };
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

      # tools used by plugin installers and their build commands
      pluginInstallPath = lib.makeBinPath [
        pkgs.git
        pkgs.cargo
        pkgs.rustc
        pkgs.gcc
        pkgs.go
        pkgs.nodejs
        pkgs.curl
      ];
    in
    {
      programs.herdr = {
        enable = true;
        package = herdrPackage;
        settings = herdrSettings;
      };

      home.packages = [ pkgs.nodejs ];

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
          # worktree auto-layout: fills every worktree workspace herdr
          # creates/opens (worktree.created/opened events); repo = "*" matches
          # any repo, a repo-specific layout file would win over it
          "herdr/plugins/config/cloudmanic.herdr-plus/worktrees/default.toml".source =
            (pkgs.formats.toml { }).generate "herdr-plus-worktree-default.toml"
              {
                repo = "*";
                tabs = [
                  {
                    name = "agent";
                    command = "omp";
                  }
                  { name = "shell"; }
                ];
              };

          # running server keeps its loaded keymap; pick up new config on switch
          "herdr/config.toml".onChange = ''
            ${herdrBin} server reload-config > /dev/null 2>&1 || true
          '';
        };

      # install plugins at their pinned commits through herdr's offline global
      # registry. The socket override avoids a protocol mismatch with a server
      # that is still running the previous Nix generation during activation.
      # installs are best-effort: a plugin may need a newer toolchain than
      # nixpkgs ships, which must not abort the whole home-manager generation.
      home.activation.herdrPlugins = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        offlineSocket="''${XDG_RUNTIME_DIR:-/tmp}/herdr-plugin-activation-$$.sock"
        if installed=$(HERDR_SOCKET_PATH="$offlineSocket" ${herdrBin} plugin list --json 2>/dev/null); then
          ${lib.concatStrings (
            lib.mapAttrsToList (id: plugin: ''
              if ! printf '%s' "$installed" | ${pkgs.jq}/bin/jq -e \
                '.result.plugins[] | select(.plugin_id == "${id}" and .source.resolved_commit == "${plugin.rev}")' \
                > /dev/null; then
                run env PATH="${pluginInstallPath}:$PATH" HERDR_SOCKET_PATH="$offlineSocket" \
                  ${herdrBin} plugin install ${plugin.source} --ref ${plugin.rev} --yes \
                  || warnEcho "herdr plugin install ${plugin.source} failed; continuing"
              fi
            '') herdrPlugins
          )}
        else
          warnEcho "herdr plugin registry unreadable; skipping plugin install (${
            lib.concatStringsSep ", " (map (plugin: plugin.source) (lib.attrValues herdrPlugins))
          })"
        fi
      '';
    };
}

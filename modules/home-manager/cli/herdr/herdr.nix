{
  flake.modules.homeManager.herdr =
    {
      config,
      inputs,
      options,
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
        experimental.pane_history = true;
        theme.name = "vesper";
        ui.toast.delivery = "herdr";
        ui.status_indicators = "symbols";
        ui.prompt_new_tab_name = false;
        ui.pane_borders = "always";
        ui.show_agent_labels_on_pane_borders = true;
        ui.sidebar.spaces.rows = [
          [
            "state_icon"
            "workspace"
          ]
          [
            "branch"
            "git_status"
            { token = "$jj_bookmark"; }
          ]
        ];
      };

      herdrPackage = inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.herdr;
      herdrBin = lib.getExe herdrPackage;

      # `herdr machine add` writes this client-side catalog imperatively; nix
      # owns it instead. herdr only needs a stable 32-hex id per entry, so
      # derive it from the target to keep it identical across hosts and
      # rebuilds.
      herdrEndpoints = pkgs.writers.writeJSON "herdr-endpoints.json" {
        version = 1;
        ssh = map (machine: {
          id = builtins.hashString "md5" machine;
          label = machine;
          target = machine;
          session = "default";
          enabled = true;
        }) config.programs.herdr.machines;
      };
    in
    {
      options.programs.herdr.machines = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "workspace" ];
        description = "ssh targets listed next to Local in the herdr sidebar.";
      };

      config = {
        programs.herdr = {
          enable = true;
          package = herdrPackage;
          settings = herdrSettings;
        };

        # herdr's claude integration installer cannot edit the nix-owned
        # settings.json; declare what `herdr integration install claude` writes
        programs.claude-code = lib.mkIf config.programs.claude-code.enable {
          hooks."herdr-agent-state.sh" =
            builtins.readFile "${inputs.herdr}/src/integration/assets/claude/herdr-agent-state.sh";
          settings.hooks.SessionStart = [
            {
              matcher = "^(startup|resume|clear|compact|fork)$";
              hooks = [
                {
                  type = "command";
                  command = "bash '${config.programs.claude-code.configDir}/hooks/herdr-agent-state.sh' session";
                  timeout = 10;
                }
              ];
            }
          ];
        };

        # users/workspace imports this module without niri
        wayland = lib.optionalAttrs (options.wayland.windowManager or { } ? niri) {
          windowManager.niri.settings.binds."Mod+E" = {
            _props.hotkey-overlay-title = "Open herdr";
            spawn = [
              "focus-or-spawn"
              "herdr.workspace"
              "ghostty"
              "--class=herdr.workspace"
              "-e"
              "herdr"
            ];
          };
        };

        home.packages = [ pkgs.local.druk ];

        xdg.configFile = {
          # running server keeps its loaded keymap; pick up new config on switch
          "herdr/config.toml".onChange = ''
            ${herdrBin} server reload-config > /dev/null 2>&1 || true
          '';
        };

        home.activation.herdrMachines = lib.mkIf (config.programs.herdr.machines != [ ]) (
          lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            run install -Dm644 ${herdrEndpoints} \
              "''${XDG_STATE_HOME:-$HOME/.local/state}/herdr/client/endpoints.json"
          ''
        );

        # the socket override avoids a protocol mismatch with a server that is
        # still running the previous Nix generation during activation.
        home.activation.herdrPlugins = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          offlineSocket="''${XDG_RUNTIME_DIR:-/tmp}/herdr-plugin-activation-$$.sock"
          run env HERDR_SOCKET_PATH="$offlineSocket" \
            ${herdrBin} plugin link ${pkgs.local.herdr-jj}/share/herdr-jj
        '';
      };
    };
}

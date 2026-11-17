{
  flake.modules.homeManager.herdrApp =
    {
      inputs,
      lib,
      options,
      pkgs,
      self,
      ...
    }:
    let
      herdr-app = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.herdr-app;
      theme = self.themes.${self.theme};

      # themes/<name>.json: terminal colors plus overrides for the panel colors
      mkTheme = mode: ansi: {
        background = mode.bg.base;
        foreground = mode.fg.base;
        selection = mode.bg.overlay;
        cursor = mode.fg.base;
        ansi = map (c: ansi.normal.${c}) ansiOrder ++ map (c: ansi.bright.${c}) ansiOrder;
        colors = {
          canvas = mode.bg.elevated;
          chrome = mode.bg.elevated;
          surface = mode.bg.surface;
          popover = mode.bg.surface;
          raised = mode.bg.overlay;
          hover = mode.bg.overlay;
          selected = mode.bg.overlay;
          border = mode.bg.overlay;
          input = mode.fg.dim;
          muted = mode.fg.muted;
          dim = mode.fg.dim;
          accent = mode.accent.primary;
          accent_foreground = mode.bg.base;
          solid = mode.accent.primary;
          solid_foreground = mode.bg.base;
          working = mode.accent.tertiary;
          blocked = mode.semantic.warning;
          done = mode.semantic.success;
          idle = mode.fg.dim;
        };
      };
      ansiOrder = [
        "black"
        "red"
        "green"
        "yellow"
        "blue"
        "magenta"
        "cyan"
        "white"
      ];

      # the shipped main layout made see-through; umbriel and niri blur behind
      # every window, window_blur asks kwin-blur compositors for it
      glassLayout = pkgs.runCommand "herdr-app-glass.json" { nativeBuildInputs = [ pkgs.jq ]; } ''
        jq '. + {
          window_blur: true,
          terminal_opacity: 0.8,
          colors: {
            canvas: "${theme.dark.bg.elevated}80",
            chrome: "${theme.dark.bg.elevated}b3",
            background: "${theme.dark.bg.base}cc"
          }
        }' ${herdr-app.src}/defaults/layouts/main.json > $out
      '';

      # the app writes settings.json itself (zoom, theme picker), so nix only
      # forces its own keys instead of owning the file
      forceSettings = pkgs.writeShellScript "herdr-app-settings" ''
        set -eu
        settings="''${XDG_CONFIG_HOME:-$HOME/.config}/herdr-app/settings.json"
        mkdir -p "$(dirname "$settings")"
        [ -e "$settings" ] || echo '{}' > "$settings"
        ${lib.getExe pkgs.jq} '.telemetry = false | .theme = { dark: "${self.theme}", light: "${self.theme}-light" }' \
          "$settings" > "$settings.tmp"
        mv "$settings.tmp" "$settings"
      '';
    in
    {
      config = lib.mkMerge [
        {
          home.packages = [ herdr-app ];

          xdg.configFile = {
            "herdr-app/themes/${self.theme}.json".text = builtins.toJSON (mkTheme theme.dark theme.ansi);
            "herdr-app/themes/${self.theme}-light.json".text = builtins.toJSON (
              mkTheme theme.light theme.light.ansi
            );
            "herdr-app/layouts/glass.json".source = glassLayout;
          };

          home.activation.herdrAppSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            run ${forceSettings}
          '';

          wayland.windowManager.niri.settings.binds."Mod+E" = {
            _props.hotkey-overlay-title = "Open herdr";
            spawn = [
              "focus-or-spawn"
              "herdr-app"
              "herdr-app"
            ];
          };
        }
        (lib.optionalAttrs (options.programs ? umbriel) {
          programs.umbriel.settings.keybinds."Mod+E" = {
            action = "spawn focus-or-spawn herdr-app herdr-app";
            repeat = false;
          };
        })
      ];
    };
}

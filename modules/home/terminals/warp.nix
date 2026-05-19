{
  flake.modules.homeManager.warpTerminal =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      cfg = config.programs.warp-terminal;
      toml = pkgs.formats.toml { };
      yaml = pkgs.formats.yaml { };
      t = config.theme;
      themeFileName = "grey-teal";
      themeName = "Grey Teal";
      tabConfigFileName = name: if lib.hasSuffix ".toml" name then name else "${name}.toml";
      defaultTabConfigPath =
        name: "${config.xdg.dataHome}/warp-terminal/tab_configs/${tabConfigFileName name}";
      settings =
        cfg.settings
        // lib.optionalAttrs (cfg.defaultTabConfig != null) {
          general = (cfg.settings.general or { }) // {
            default_session_mode = "tab_config";
            default_tab_config_path = defaultTabConfigPath cfg.defaultTabConfig;
          };
        };
    in
    {
      options.programs.warp-terminal = {
        enable = lib.mkEnableOption "Warp terminal";

        package = lib.mkPackageOption pkgs.custom "warp-terminal" { };

        settings = lib.mkOption {
          inherit (toml) type;
          default = { };
          description = "settings written to ~/.config/warp-terminal/settings.toml.";
        };

        tabConfigs = lib.mkOption {
          type = lib.types.attrsOf toml.type;
          default = { };
          description = "tab configs written to ~/.local/share/warp-terminal/tab_configs/<name>.toml.";
        };

        themes = lib.mkOption {
          type = lib.types.attrsOf yaml.type;
          default = { };
          description = "themes written to ~/.local/share/warp-terminal/themes/<name>.yaml.";
        };

        defaultTabConfig = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "tab config name to start by default. also sets general.default_session_mode.";
        };
      };

      config = lib.mkMerge [
        {
          programs.warp-terminal = {
            enable = lib.mkDefault true;
            themes.${themeFileName} = {
              name = themeName;
              accent = t.dark.accent.primary;
              cursor = t.dark.accent.primary;
              background = t.dark.bg.base;
              foreground = t.dark.fg.base;
              details = "darker";
              terminal_colors = {
                normal = {
                  black = t.dark.bg.surface;
                  red = t.dark.semantic.error;
                  green = t.ansi.normal.green;
                  yellow = t.dark.semantic.warning;
                  blue = t.ansi.normal.blue;
                  magenta = t.ansi.normal.magenta;
                  cyan = t.ansi.normal.cyan;
                  white = t.dark.fg.base;
                };
                bright = {
                  black = t.dark.fg.dim;
                  red = t.dark.semantic.error;
                  green = t.ansi.normal.green;
                  yellow = t.dark.semantic.warning;
                  blue = t.ansi.normal.blue;
                  magenta = t.ansi.normal.magenta;
                  cyan = t.ansi.normal.cyan;
                  white = "#FFFFFF";
                };
              };
            };

            settings = {
              appearance = {
                text = {
                  notebook_font_size = 14.0;
                  font_size = 13.0;
                  font_name = t.fonts.mono;
                };
                themes = {
                  theme.custom = {
                    name = themeName;
                    path = "${config.xdg.dataHome}/warp-terminal/themes/${themeFileName}.yaml";
                  };
                  system_theme = false;
                };
                vertical_tabs = {
                  primary_info = "command";
                  display_granularity = "panes";
                  enabled = true;
                  view_mode = "compact";
                  compact_subtitle = "working_directory";
                };
                window.override_opacity = 80;
              };

              privacy = {
                telemetry_enabled = false;
                crash_reporting_enabled = false;
              };

              agents = {
                cloud_conversation_storage_enabled = false;
                third_party = {
                  should_render_cli_agent_toolbar = true;
                  auto_dismiss_composer_after_submit = false;
                  auto_open_composer_on_cli_agent_start = false;
                };
                warp_agent = {
                  is_any_ai_enabled = false;
                  other = {
                    show_conversation_history = false;
                    show_agent_notifications = false;
                  };
                };
              };

              terminal = {
                use_audible_bell = true;
                input = {
                  honor_ps1 = true;
                  input_box_type_setting = "classic";
                  syntax_highlighting = true;
                };
              };

              code.editor = {
                show_global_search = true;
                show_project_explorer = true;
                show_code_review_button = true;
                auto_open_code_review_pane_on_first_agent_change = false;
                open_file_editor = "system_default";
              };

              notifications = {
                toast_duration_secs = 8;
                preferences = {
                  is_agent_task_completed_enabled = false;
                  is_long_running_enabled = true;
                  is_needs_attention_enabled = true;
                  is_password_prompt_enabled = true;
                  long_running_threshold = 30;
                  mode = "enabled";
                  play_notification_sound = true;
                };
              };

              warp_drive.enabled = false;
            };

            defaultTabConfig = "nixfiles";

            tabConfigs.nixfiles = {
              name = "nixfiles";
              color = "green";
              panes = [
                {
                  id = "root";
                  split = "vertical";
                  children = [
                    "pi"
                    "terminal"
                  ];
                }
                {
                  id = "pi";
                  type = "terminal";
                  is_focused = true;
                  directory = "/home/simon/code/nixfiles";
                  commands = [ "pi" ];
                }
                {
                  id = "terminal";
                  type = "terminal";
                  directory = "/home/simon/code/nixfiles";
                }
              ];
            };
          };
        }

        (lib.mkIf cfg.enable {
          home.packages = [ cfg.package ];

          xdg.configFile."warp-terminal/settings.toml" = lib.mkIf (settings != { }) {
            source = toml.generate "warp-settings.toml" settings;
          };

          xdg.dataFile =
            (lib.mapAttrs' (
              name: value:
              lib.nameValuePair "warp-terminal/themes/${name}.yaml" {
                source = yaml.generate "warp-theme-${name}.yaml" value;
                force = true;
              }
            ) cfg.themes)
            // (lib.mapAttrs' (
              name: value:
              lib.nameValuePair "warp-terminal/tab_configs/${tabConfigFileName name}" {
                source = toml.generate "warp-tab-config-${tabConfigFileName name}" value;
              }
            ) cfg.tabConfigs);
        })
      ];
    };
}

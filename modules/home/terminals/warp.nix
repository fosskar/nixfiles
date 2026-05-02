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
          description = "themes written to ~/.warp/themes/<name>.yaml.";
        };

        defaultTabConfig = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "tab config name to start by default. also sets general.default_session_mode.";
        };
      };

      config = lib.mkIf cfg.enable {
        home.packages = [ cfg.package ];

        xdg.configFile."warp-terminal/settings.toml" = lib.mkIf (settings != { }) {
          source = toml.generate "warp-settings.toml" settings;
        };

        home.file = lib.mapAttrs' (
          name: value:
          lib.nameValuePair ".warp/themes/${name}.yaml" {
            source = yaml.generate "warp-theme-${name}.yaml" value;
          }
        ) cfg.themes;

        xdg.dataFile = lib.mapAttrs' (
          name: value:
          lib.nameValuePair "warp-terminal/tab_configs/${tabConfigFileName name}" {
            source = toml.generate "warp-tab-config-${tabConfigFileName name}" value;
          }
        ) cfg.tabConfigs;
      };
    };
}

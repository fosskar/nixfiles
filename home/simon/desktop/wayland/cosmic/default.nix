{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:

with lib;

let
  cfg = config.module.desktop.wayland.cosmic;

  inherit (config.lib.cosmic) Actions mapBinds;
in

{
  imports = [
    inputs.home-manager-cosmic.homeManagerModules.cosmic
  ];
  options = {
    module.desktop.wayland.cosmic.enable = mkEnableOption "Enables cosmic";
  };

  config = mkIf cfg.enable {
    programs.cosmic = {
      enable = true;
      input.asDefaults = true;
      input.binds =
        mapBinds {
          # Navigation
          Super = {
            "h" = Actions.Focus "Left";
            "l" = Actions.Focus "Right";
            "j" = Actions.Focus "Down";
            "k" = Actions.Focus "Up";
            "u" = Actions.Focus "Out";
            "i" = Actions.Focus "In";
            Shift = {
              "h" = Actions.Move "Left";
              "l" = Actions.Move "Right";
              "j" = Actions.Move "Down";
              "k" = Actions.Move "Up";
              "1" = Actions.MoveToWorkspace 1;
              "2" = Actions.MoveToWorkspace 2;
              "3" = Actions.MoveToWorkspace 3;
              "4" = Actions.MoveToWorkspace 4;
              "5" = Actions.MoveToWorkspace 5;
              "q" = Actions.Close;
              "v" = Actions.ToggleStacking;
              "y" = Actions.ToggleSticky;
            };
            "1" = Actions.Workspace 1;
            "2" = Actions.Workspace 2;
            "3" = Actions.Workspace 3;
            "4" = Actions.Workspace 4;
            "5" = Actions.Workspace 5;
            #"v" = Actions.ToggleWindowFloating;
            "f" = Actions.Maximize;
            "m" = Actions.Minimize;
            # System
            "t" = Actions.Spawn pkgs.wezterm;
            "w" = Actions.Spawn inputs.zen-browser.packages.${pkgs.system}.default;
            "z" = Actions.Spawn pkgs.zed-editor;
            "o" = Actions.Spawn pkgs.teamspeak3;
            "e" = Actions.System "HomeFolder";
            Print = Actions.System "Screenshot";
            Next = Actions.Spawn "${config.xdg.configHome}/hypr/hypr-gamemode.sh";
          };
        }
        ++ [
          {
            modifiers = [ "Super" ];
            action = "Disable";
          }
        ];
      #background = {
      #  displays = {
      #    all = {
      #      source = "/example/img.png";
      #    };
      #  };
      #};
      #panels = {
      #  "Bar" = {
      #    applets = {
      #      start = [ "com.system76.CosmicAppletWorkspaces" ];
      #      center = [ "com.system76.CosmicAppletMinimize" ];
      #      end = [
      #        "com.system76.CosmicAppletTime"
      #        "com.system76.CosmicAppletTiling"
      #        "com.system76.CosmicAppletAudio"
      #        "com.system76.CosmicAppletNetwork"
      #        "com.system76.CosmicAppletNotifications"
      #        "com.system76.CosmicAppletStatusArea"
      #        "com.system76.CosmicAppletPower"
      #      ];
      #    };
      #    options = {
      #      size = "XS";
      #      border_radius = 0;
      #    };
      #  };
      #};
      comp.settings = {
        autotile = true;
        active_hint = true;
        focus_follows_cursor = false;
        focus_follows_cursor_delay = 0;
        cursor_follows_focus = false;
      };
    };
  };
}

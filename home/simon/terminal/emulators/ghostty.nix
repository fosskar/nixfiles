{
  config,
  lib,
  pkgs,
  ...
}:
with lib;

let
  cfg = config.module.terminal.emulators.ghostty;
in
{
  options.module.terminal.emulators.ghostty = {
    enable = mkEnableOption "Enable ghostty";
  };

  config = mkIf cfg.enable {
    programs.ghostty = {
      enable = true;
      package = pkgs.ghostty; # the stable version
      # package = ghostty.packages.${pkgs.system}.default;
      settings = {
        theme = "Adwaita Dark";
        font-family = "JetBrainsMono Nerd Font";
        font-size = 10;
        background-opacity = 1;
        copy-on-select = false;
        gtk-titlebar = false;
        adw-toolbar-style = "flat";
        window-padding-x = 4;
        window-padding-y = 4;
        window-padding-balance = true;
        confirm-close-surface = false;
        keybind = [
          "ctrl+left=goto_split:left"
          "ctrl+right=goto_split:right"
          "ctrl+up=goto_split:top"
          "ctrl+down=goto_split:bottom"
          "ctrl+comma=open_config"
          "ctrl+page_down=next_tab"
          "ctrl+shift+v=paste_from_clipboard"
          "shift+insert=paste_from_selection"
          "ctrl+shift+a=select_all"
          "shift+up=adjust_selection:up"
          "alt+five=goto_tab:5"
          "super+ctrl+right_bracket=goto_split:next"
          "ctrl+equal=increase_font_size:1"
          "ctrl+shift+o=new_split:right"
          "ctrl+shift+c=copy_to_clipboard"
          "ctrl+shift+q=quit"
          "ctrl+shift+n=new_window"
          "ctrl+shift+page_down=jump_to_prompt:1"
          "ctrl+shift+comma=reload_config"
          "ctrl+minus=decrease_font_size:1"
          "shift+left=adjust_selection:left"
          "super+ctrl+shift+up=resize_split:up,10"
          "alt+eight=goto_tab:8"
          "shift+page_up=scroll_page_up"
          "ctrl+alt+shift+j=write_scrollback_file:open"
          "ctrl+shift+left=previous_tab"
          "ctrl+shift+w=close_surface"
          "super+ctrl+shift+equal=equalize_splits"
          "shift+end=scroll_to_bottom"
          "ctrl+zero=reset_font_size"
          "alt+three=goto_tab:3"
          "ctrl+shift+j=write_scrollback_file:paste"
          "ctrl+enter=toggle_fullscreen"
          "ctrl+page_up=previous_tab"
          "shift+right=adjust_selection:right"
          "ctrl+tab=next_tab"
          "shift+page_down=scroll_page_down"
          "ctrl+shift+right=next_tab"
          "ctrl+shift+page_up=jump_to_prompt:-1"
          "alt+nine=last_tab"
          "ctrl+shift+t=new_tab"
          "shift+down=adjust_selection:down"
          "super+ctrl+shift+left=resize_split:left,10"
          "ctrl+shift+tab=previous_tab"
          "alt+two=goto_tab:2"
          "super+ctrl+shift+down=resize_split:down,10"
          "super+ctrl+shift+right=resize_split:right,10"
          "ctrl+plus=increase_font_size:1"
          "alt+four=goto_tab:4"
          "ctrl+shift+e=new_split:down"
          "alt+f4=close_window"
          "alt+one=goto_tab:1"
          "ctrl+shift+enter=toggle_split_zoom"
          "shift+home=scroll_to_top"
          "super+ctrl+left_bracket=goto_split:previous"
          "ctrl+shift+i=inspector:toggle"
          "alt+six=goto_tab:6"
          "alt+seven=goto_tab:7"
        ];
      };
    };
  };
}

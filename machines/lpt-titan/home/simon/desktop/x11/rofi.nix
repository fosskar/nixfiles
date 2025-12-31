{ config, ... }:
let
  bg0 = "#212121";
  bg1 = "#2A2A2A";
  bg2 = "#78A1BB";
  bg3 = "#78A1BB";
  fg0 = "#E6E6E6";
  #fg1 = "#FFFFFF";
  fg2 = "#969696";
  fg3 = "#3D3D3D";
  inherit (config.lib.formats.rasi) mkLiteral;
in
{
  programs.rofi = {
    enable = true;
    terminal = "\${pkgs.wezterm}/bin/wezterm";
    font = "Inter 12";
    location = "top";
    plugins = [ ];
    theme = {
      "*" = {
        font = "Inter 12";
        background-color = mkLiteral "transparent";
        text-color = mkLiteral fg0;

        margin = "0px";
        padding = "0px";
        spacing = "0px";
      };

      "#window" = {
        location = mkLiteral "center";
        width = 500;
        border-radius = mkLiteral "2px";

        background-color = mkLiteral bg0;
      };

      "#mainbox" = {
        padding = mkLiteral "12px";
      };

      "#inputbar" = {
        background-color = mkLiteral bg1;
        border-color = mkLiteral bg3;

        border = mkLiteral "2px";
        border-radius = mkLiteral "1px";

        padding = mkLiteral "8px 16px";
        spacing = mkLiteral "8px";

        children = map mkLiteral [
          "prompt"
          "entry"
        ];
      };

      "#prompt" = {
        text-color = mkLiteral fg2;
      };

      "#entry" = {
        placeholder = "Search";
        placeholder-color = fg3;
      };

      "#message" = {
        margin = mkLiteral "12px 0 0";
        border-radius = mkLiteral "1px";
        border-color = mkLiteral bg2;
        background-color = mkLiteral bg2;
      };

      "#textbox" = {
        padding = mkLiteral "8px 24px";
      };

      "#listview" = {
        background-color = mkLiteral "transparent";

        margin = mkLiteral "12px 0 0";
        lines = mkLiteral "8";
        columns = mkLiteral "1";

        fixed-height = false;
      };

      "#element" = {
        padding = mkLiteral "8px 16px";
        spacing = mkLiteral "8px";
        border-radius = mkLiteral "1px";
      };

      "#element normal active" = {
        text-color = mkLiteral bg3;
      };

      "#element alternate active" = {
        text-color = mkLiteral bg3;
      };

      "#element selected normal, element selected active" = {
        background-color = mkLiteral bg3;
        text-color = mkLiteral bg0;
      };

      "element-icon" = {
        size = mkLiteral "1em";
        vertical-align = mkLiteral "0.5";
      };

      "#element-text" = {
        text-color = mkLiteral "inherit";
      };
    };
  };
}

{ pkgs, ... }:
{
  xsession.windowManager.i3 = {
    config = {
      menu = "rofi -show drun -show-icons";
      workspaceAutoBackAndForth = true;
      defaultWorkspace = "1";

      startup = [
        { command = "--no-startup-id bitwarden"; }
        { command = "--no-startup-id autorandr -c --default default"; }
      ];

      focus = {
        followMouse = false;
        mouseWarping = false;
      };

      colors = {
        focused = {
          background = "#232528";
          border = "#78A1BB";
          childBorder = "#78A1BB";
          indicator = "#78A1BB";
          text = "#EBF5EE";
        };
        focusedInactive = {
          background = "#232528";
          border = "#232528";
          childBorder = "#232528";
          indicator = "#232528";
          text = "#EBF5EE";
        };
        unfocused = {
          background = "#232528";
          border = "#232528";
          childBorder = "#232528";
          indicator = "#232528";
          text = "#EBF5EE";
        };
        urgent = {
          background = "#232528";
          border = "#E4572E";
          childBorder = "#E4572E";
          indicator = "#E4572E";
          text = "#232528";
        };
        placeholder = {
          background = "#232528";
          border = "#588157";
          childBorder = "#588157";
          indicator = "#588157";
          text = "#EBF5EE";
        };
      };

      window = {
        titlebar = false;
        border = 1;
        hideEdgeBorders = "smart";
      };

      terminal = "${pkgs.wezterm}/bin/wezterm";

      fonts = {
        names = [ "Inter" ];
        size = 16.0;
      };
      gaps = {
        inner = 1;
        outer = 2;
        smartGaps = true;
        smartBorders = "on";
      };

      floating = {
        titlebar = false;
        border = 1;
        criteria = [
          { window_role = "pop-up"; }
          { class = "^KeePassXC$"; }
          { class = "^zoom$"; }
          { class = "^Bitwarden$"; }
          { class = "^.blueman-manager-wrapped$"; }
          { class = "^pwvucontrol$"; }
          { class = "slack"; }
        ];
      };
    };
  };
}

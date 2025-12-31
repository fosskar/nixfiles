{ pkgs, ... }:
{
  xsession.windowManager.i3 = {
    config = {
      bars = [
        {
          fonts = {
            names = [ "Inter" ];
            style = "normal";
            size = 9.0;
          };
          statusCommand = "${pkgs.i3status-rust}/bin/i3status-rs ~/.config/i3status-rust/config-custom.toml";
          position = "top";
          workspaceButtons = true;
          trayOutput = "primary";
          trayPadding = 2;
          colors = {
            background = "#232528";
            statusline = "#232528";
            separator = "#232528";
            focusedWorkspace = {
              background = "#78A1BB";
              border = "#78A1BB";
              text = "#232528";
            };
            activeWorkspace = {
              background = "#333333";
              border = "#78A1BB";
              text = "#EBF5EE";
            };
            inactiveWorkspace = {
              background = "#232528";
              border = "#232528";
              text = "#EBF5EE";
            };
            urgentWorkspace = {
              background = "#C84630";
              border = "#C84630";
              text = "#232528";
            };
          };
        }
      ];
    };
  };
}

_: {
  # desktop-specific niri settings
  programs.niri.settings = {
    # output configuration
    outputs = {
      "DP-1" = {
        focus-at-startup = true;
        mode = {
          width = 3440;
          height = 1440;
          refresh = 164.900;
        };
        scale = 1.0;
        transform.rotation = 0;
        position = {
          x = 0;
          y = 0;
        };
      };

      "HDMI-A-2" = {
        variable-refresh-rate = true;
        mode = {
          width = 1920;
          height = 1080;
          refresh = 239.761;
        };
        scale = 1.0;
        transform.rotation = 270;
        position = {
          x = 3440;
          y = -450;
        };
      };
    };

    # workspace->output assignments
    workspaces = {
      primary.open-on-output = "DP-1";
      secondary.open-on-output = "HDMI-A-2";
    };

    # element to secondary workspace (desktop only, has second monitor)
    window-rules = [
      {
        matches = [
          { app-id = "^Element$"; }
        ];
        open-on-workspace = "secondary";
      }
    ];

    # desktop-only startup apps
    spawn-at-startup = [
      { sh = "steam -silent"; }
    ];
  };
}

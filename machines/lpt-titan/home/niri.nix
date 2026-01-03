_: {
  # desktop-specific niri settings
  programs.niri.settings = {
    # output configuration
    outputs = {
      "eDP-1" = {
        variable-refresh-rate = true;
        mode = {
          width = 2880;
          height = 1920;
          refresh = 120.000;
        };
        scale = 1.75;
        transform.rotation = 0;
        position = {
          x = 0;
          y = 0;
        };
      };
    };

    # workspace->output assignments
    workspaces = {
      primary.open-on-output = "eDP-1";
    };

    # desktop-only startup apps
    spawn-at-startup = [
    ];
  };
}

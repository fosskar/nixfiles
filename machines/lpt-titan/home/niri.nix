_: {
  # desktop-specific niri settings
  wayland.windowManager.niri.settings = {
    # outputs managed by kanshi

    # workspace->output assignments
    workspace = [
      {
        _args = [ "primary" ];
        open-on-output = "eDP-1";
      }
    ];
  };
}

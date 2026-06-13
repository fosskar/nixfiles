_: {
  # desktop-specific niri settings
  wayland.windowManager.niri.settings = {
    # outputs managed by kanshi

    # workspace->output assignments
    workspace = [
      {
        _args = [ "1" ];
        open-on-output = "DP-1";
      }
      {
        _args = [ "2" ];
        open-on-output = "HDMI-A-2";
      }
    ];

    # element to secondary workspace (desktop only, has second monitor)
    window-rule = [
      {
        match = [
          { _props.app-id = "^Element$"; }
          { _props.app-id = "^element$"; }
          { _props.app-id = "^io\\.element\\.desktop$"; }
          # Element reports `electron` as app-id here; keep specific IDs for builds that set them correctly.
          {
            _props = {
              app-id = "^electron$";
              title = ".*Element.*";
            };
          }
          { _props.app-id = "^steam$"; }
        ];
        open-on-workspace = "2";
      }
      {
        match = [
          { _props.app-id = "^dev\\.zed\\.Zed(-Nightly)?$"; }
        ];
        default-column-width.fixed = 1800;
      }
      {
        match = [
          { _props.app-id = "^zen-beta$"; }
        ];
        default-column-width.fixed = 1700;
      }
    ];

    # desktop-only startup apps
    spawn-sh-at-startup = [ [ "steam -silent" ] ];
  };
}

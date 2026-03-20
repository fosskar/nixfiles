_: {
  # desktop-specific niri settings
  programs.niri.settings = {
    # outputs managed by kanshi

    # workspace->output assignments
    workspaces = {
      "1".open-on-output = "DP-1";
      "2".open-on-output = "HDMI-A-2";
    };

    # element to secondary workspace (desktop only, has second monitor)
    window-rules = [
      {
        matches = [
          { app-id = "^Element$"; }
        ];
        open-on-workspace = "2";
      }
    ];

    # desktop-only startup apps
    spawn-at-startup = [
      { sh = "steam -silent"; }
    ];
  };
}

_: {
  # desktop-specific niri settings
  programs.niri.settings = {
    # outputs managed by kanshi

    # workspace->output assignments
    workspaces = {
      primary.open-on-output = "eDP-1";
    };

    # desktop-only startup apps
    spawn-at-startup = [
    ];
  };
}

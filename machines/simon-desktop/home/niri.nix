_: {
  # desktop-specific niri settings
  programs.niri.settings = {
    # toggle the spaces-os pi-chat panel
    binds."Mod+A" = {
      action.spawn = "pi-chat-toggle";
      hotkey-overlay.title = "Toggle pi-chat";
    };
    # toggle voxtype voice-to-text recording
    binds."Mod+S" = {
      action.spawn = [
        "voxtype"
        "record"
        "toggle"
      ];
      hotkey-overlay.title = "Toggle voice-to-text";
    };

    # outputs managed by kanshi

    # workspace->output assignments
    workspaces = {
      "1" = {
        name = "1";
        open-on-output = "DP-1";
      };
      "2" = {
        name = "2";
        open-on-output = "HDMI-A-2";
      };
    };

    # element to secondary workspace (desktop only, has second monitor)
    window-rules = [
      {
        matches = [
          { app-id = "^Element$"; }
          { app-id = "^element$"; }
          { app-id = "^io\\.element\\.desktop$"; }
          # Element reports `electron` as app-id here; keep specific IDs for builds that set them correctly.
          {
            app-id = "^electron$";
            title = ".*Element.*";
          }
          { app-id = "^steam$"; }
        ];
        open-on-workspace = "2";
      }
      {
        matches = [
          { app-id = "^dev\\.zed\\.Zed(-Nightly)?$"; }
        ];
        default-column-width = {
          fixed = 1800;
        };
      }
      {
        matches = [
          { app-id = "^zen-beta$"; }
        ];
        default-column-width = {
          fixed = 1700;
        };
      }
    ];

    # desktop-only startup apps
    spawn-at-startup = [
      { sh = "steam -silent"; }
    ];
  };
}

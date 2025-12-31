_: {
  xsession.windowManager.i3 = {
    config = {
      # Workspace to monitor assignments
      # Workspaces will appear on the first available monitor in each list
      workspaceOutputAssign = [
        # Main workspaces (1-5) - Primary monitors
        # Home: DP-1 (ultrawide), Office: DP-1-2, Fallback: eDP-1 (laptop)
        {
          workspace = "1";
          output = [
            "DP-1"
            "DP-1-2"
            "eDP-1"
          ];
        }
        {
          workspace = "2";
          output = [
            "DP-1"
            "DP-1-2"
            "eDP-1"
          ];
        }
        {
          workspace = "3";
          output = [
            "DP-1"
            "DP-1-2"
            "eDP-1"
          ];
        }
        {
          workspace = "4";
          output = [
            "DP-1"
            "DP-1-2"
            "eDP-1"
          ];
        }
        {
          workspace = "5";
          output = [
            "DP-1"
            "DP-1-2"
            "eDP-1"
          ];
        }

        # Secondary workspaces (6-8) - Secondary monitors
        # Home: DP-2-2 (vertical), Office: DP-1-3, Fallback: eDP-1 (laptop)
        {
          workspace = "6";
          output = [
            "DP-2-2"
            "DP-1-3"
            "eDP-1"
          ];
        }
        {
          workspace = "7";
          output = [
            "DP-2-2"
            "DP-1-3"
            "eDP-1"
          ];
        }
        {
          workspace = "8";
          output = [
            "DP-2-2"
            "DP-1-3"
            "eDP-1"
          ];
        }

        # Tertiary workspaces (9-10) - Laptop or third monitor
        # Prefer laptop screen, fallback to secondary monitors
        {
          workspace = "9";
          output = [
            "eDP-1"
            "DP-2-2"
            "DP-1-3"
          ];
        }
        {
          workspace = "10";
          output = [
            "eDP-1"
            "DP-2-2"
            "DP-1-3"
          ];
        }
      ];
    };
  };
}

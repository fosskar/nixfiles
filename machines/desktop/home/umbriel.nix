_: {
  programs.umbriel.settings = {
    keybinds."Mod+S" = {
      action = "spawn focus-or-spawn steam steam";
      repeat = false;
    };

    # aw3423dwf qd-oled; kanshi still sets mode and position
    output."DP-1" = {
      hdr = "on";
      vrr = "disabled";
      # only allows tearing; the game rule below requests it
      tearing = true;
    };

    window_rule = [
      {
        # cs2 runs native, deadlock under proton; steam_app_730 covers cs2 under proton
        match.app_id = [
          "^cs2$"
          "^steam_app_730$"
          "^steam_app_1422450$"
        ];
        hdr = "off";
        tearing = true;
      }
    ];
  };
}

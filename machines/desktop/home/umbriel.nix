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
      # only allows tearing; the gaming feature's window rule requests it
      tearing = true;
    };
  };
}

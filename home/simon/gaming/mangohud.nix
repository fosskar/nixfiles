_: {
  programs.mangohud = {
    enable = true;
    enableSessionWide = false;
    settings = {
      fps_limit = "400";
      toggle_fps_limit = "F3";
      vsync = 1;
      gl_vsync = 0;
      legacy_layout = false;
      gpu_stats = false;
      cpu_stats = false;
      vram = false;
      fps = true;
      frametime = true;
      frame_timing = false;
      frametime_color = "00ff00";
      show_fps_limit = true;
      gamemode = true;
      vkbasalt = true;
      throttling_status = true;
      background_alpha = 0.4;
      font_size = 14;

      background_color = 20202;
      position = "top-left";
      text_color = "ffffff";
      round_corners = 5;
      hud_no_margin = true;
      hud_compact = true;
      toggle_hud = "Shift_R + F12";
      toggle_logging = "Shift_L + F2";
      upload_log = "F5";
    };
  };
}

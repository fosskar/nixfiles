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
      gpu_stats = true;
      gpu_temp = true;
      gpu_power = true;
      gpu_text = "GPU";
      cpu_stats = true;
      cpu_temp = true;
      cpu_color = "2e97cb";
      cpu_text = "CPU";
      io_color = "a491d3";
      vram = true;
      vram_color = "ad64c1";
      ram_color = "c26693";
      fps = true;
      engine_color = "eb5b5b";
      gpu_color = "2e9762";
      vulkan_driver = true;
      wine_color = "eb5b5b";
      frame_timing = 0;
      frametime_color = "00ff00";
      show_fps_limit = true;
      gamemode = true;
      media_player_color = "ffffff";
      background_alpha = 0.4;
      font_size = 14;

      background_color = 020202;
      position = "top-left";
      text_color = "ffffff";
      round_corners = 5;
      toggle_hud = "Shift_R + F12";
      toggle_logging = "Shift_L + F2";
      upload_log = "F5";
    };
  };
}

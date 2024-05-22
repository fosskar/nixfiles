_: let
  xdg.configHome = let
    x = builtins.getEnv "XDG_CONFIG_HOME";
  in
    if x != ""
    then x
    else "${builtins.getEnv "HOME"}/.config";
in {
  home.file."${xdg.configHome}/vkBasalt/vkBasalt.conf".text = ''
    effects = cas
    toggleKey = Home
    enableOnLaunch = True
    casSharpness = 0.4
  '';

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
      #gpu_temp = false;
      #gpu_power = false;
      #gpu_text = "GPU";
      #gpu_color = "2e9762";
      cpu_stats = false;
      #cpu_temp = false;
      #cpu_color = "2e97cb";
      #cpu_text = "CPU";
      vram = false;
      #vram_color = "ad64c1";
      #ram_color = "c26693";
      fps = true;
      #engine_color = "eb5b5b";
      #vulkan_driver = true;
      #wine_color = "eb5b5b";
      frametime = true;
      frame_timing = false;
      frametime_color = "00ff00";
      show_fps_limit = true;
      gamemode = true;
      vkbasalt = true;
      throttling_status = true;
      #media_player_color = "ffffff";
      background_alpha = 0.4;
      font_size = 14;

      background_color = 020202;
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

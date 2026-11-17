_: {
  programs.noctalia.settings.idle.behavior = {
    lock.timeout = 900;
    suspend.timeout = 1800;
  };

  programs.noctalia.settings.lockscreen_widgets.widget."lockscreen-login-box@eDP-1" = {
    type = "login_box";
    output = "eDP-1";
    cx = 823.0;
    cy = 978.0;
    box_width = 400.0;
    box_height = 70.0;
    rotation = 0.0;
    settings = {
      layout = "compact";
      show_media = false;
    };
  };
}

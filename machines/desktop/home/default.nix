{
  nflib,
  self,
  ...
}:
{
  home-manager.users.simon = {
    imports = [
      self.modules.homeManager.buzz
      self.modules.homeManager.gaming
      self.modules.homeManager.herdr
      self.modules.homeManager.noctalia
    ]
    ++ nflib.scanPaths ./. { };
    programs.noctalia.settings.lockscreen_widgets.widget = {
      "lockscreen-login-box@DP-1" = {
        type = "login_box";
        output = "DP-1";
        cx = 1720.0;
        cy = 1321.0;
        box_width = 400.0;
        box_height = 70.0;
        rotation = 0.0;
        settings = {
          layout = "compact";
          show_media = false;
        };
      };
      "lockscreen-login-box@HDMI-A-2" = {
        type = "login_box";
        output = "HDMI-A-2";
        cx = 960.0;
        cy = 961.0;
        box_width = 400.0;
        box_height = 70.0;
        rotation = 0.0;
        settings = {
          layout = "compact";
          show_media = false;
        };
      };
    };
  };
}

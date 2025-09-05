_: {
  programs.sherlock = {
    enable = true;
    settings = {
      aliases = {
        WebCord = {
          name = "Discord";
        };
      };
      ignore = ''
        Avahi*
      '';
      launchers = [
        {
          name = "App Launcher";
          type = "app_launcher";
          args = { };
          priority = 1;
          home = true;
        }
      ];
    };
  };
}

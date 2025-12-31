_: {
  programs.ghostty = {
    enable = true;
    settings = {
      theme = "Adwaita Dark";
      font-family = "JetBrainsMono Nerd Font";
      font-size = 10; # default: 12
      background-opacity = 0.90; # default: 1.0
      background-blur = true; # default: false

      copy-on-select = false; # default: true
      confirm-close-surface = false; # default: true

      gtk-titlebar = false; # default: true

      window-padding-x = 4; # default: 2
      window-padding-y = 4; # default: 2
      window-padding-balance = true; # default: false

    };
  };
}

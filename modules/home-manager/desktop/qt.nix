_: {
  flake.modules.homeManager.qt = _: {
    qt = {
      enable = true;
      platformTheme = {
        name = "qtct"; # gtk4
      };
      style = {
        name = "adwaita-dark";
      };
    };
  };
}

_: {
  flake.modules.homeManager.qt =
    { config, ... }:
    let
      # the colors file comes from noctalia's qt template
      qtct = name: {
        Appearance = {
          style = "Fusion";
          custom_palette = true;
          color_scheme_path = "${config.xdg.configHome}/${name}/colors/noctalia.conf";
          icon_theme = "Papirus-Dark";
        };
      };
    in
    {
      qt = {
        enable = true;
        platformTheme.name = "qtct";
        qt5ctSettings = qtct "qt5ct";
        qt6ctSettings = qtct "qt6ct";
      };
    };
}

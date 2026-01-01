{ pkgs, ... }:
{

  home.packages = with pkgs; [
    kdePackages.qt6ct
  ];

  qt = {
    enable = true;
    platformTheme = {
      name = "qtct"; # gtk4
    };
    style = {
      name = "adwaita-dark";
    };
  };
}

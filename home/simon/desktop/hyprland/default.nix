{
  mylib,
  pkgs,
  inputs,
  ...
}:
{
  imports = mylib.scanPaths ./. {
    exclude = [
      "plugins.nix"
    ];
  };

  home.packages = with pkgs; [
    kdePackages.xwaylandvideobridge # for screensharing xwayland application
    kdePackages.qt6ct
    hyprshot # screenshot
    wl-clipboard # wayland clipboard
    hyprpicker # color picker
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    portalPackage =
      inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
  };
}

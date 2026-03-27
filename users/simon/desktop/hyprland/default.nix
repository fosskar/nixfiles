{
  mylib,
  #inputs,
  ...
}:
{
  imports = mylib.scanPaths ./. {
    exclude = [
      "hypridle.nix"
      "hyprlock.nix"
      "plugins.nix"
    ];
  };

  home.packages = [
    #hyprshot # screenshot
    #wl-clipboard # wayland clipboard
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    #package = null;
    #portalPackage = null;
    systemd = {
      enable = true;
      variables = [ "--all" ];
    };
  };
}

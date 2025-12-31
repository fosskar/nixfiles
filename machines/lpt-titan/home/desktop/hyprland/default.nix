{
  mylib,
  pkgs,
  inputs,
  ...
}:
{
  imports = mylib.scanPaths ./. {
    exclude = [
      "hyprpaper.nix"
      "hypridle.nix"
      "hyprlock.nix"
    ];
  };

  home.packages = with pkgs; [
    hyprshot # screenshot
    wl-clipboard # wayland clipboard
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    portalPackage =
      inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
    systemd = {
      enable = true;
      variables = [ "--all" ];
    };
  };
}

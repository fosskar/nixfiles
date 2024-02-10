{pkgs, ...}: {
  home.packages = with pkgs; [
    swww
    pywal
    webcord-vencord
    element-desktop
  ];
}

{pkgs, ...}: {
  home.packages = with pkgs; [
    webcord-vencord
    element-desktop
  ];
}

{pkgs, ...}: {
  home.packages = with pkgs; [
    swww
    brightnessctl
    gnome.gnome-bluetooth_1_0
    (python311.withPackages (p: [p.python-pam]))
    bun
    dart-sass
    fd
  ];

  programs.ags = {
    enable = true;
    configDir = ./style1;
    extraPackages = [pkgs.accountsservice];
  };
}

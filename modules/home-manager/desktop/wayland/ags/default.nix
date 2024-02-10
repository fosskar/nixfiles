{
  self,
  inputs,
  pkgs,
  ...
}: {
  imports = [inputs.ags.homeManagerModules.default];

  home.packages = with pkgs; [
    sassc
    brightnessctl
    gnome.gnome-bluetooth_1_0
    (python311.withPackages (p: [p.python-pam]))
  ];

  programs.ags = {
    enable = true;
    configDir = ./style1;
    extraPackages = [pkgs.libsoup_3];
  };
}

{
  self,
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.ags.homeManagerModules.default
    inputs.matugen.nixosModules.default
  ];

  home.packages = with pkgs; [
    swww
    brightnessctl
    gnome.gnome-bluetooth_1_0
    (python311.withPackages (p: [p.python-pam]))
    bun
    dart-sass
    fd
    inputs.matugen.packages.${system}.default
  ];

  programs.ags = {
    enable = true;
    configDir = ./style2;
    extraPackages = [pkgs.libsoup_3];
  };
}

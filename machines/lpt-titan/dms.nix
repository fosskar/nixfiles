{ inputs, ... }:
{
  imports = [
    inputs.dms.nixosModules.greeter
  ];
  programs.dank-material-shell.greeter = {
    enable = true;
    compositor.name = "niri"; # or set to hyprland
    configHome = "/home/simon";
    #quickshell.package = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;
  };
}

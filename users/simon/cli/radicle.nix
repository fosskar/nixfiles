{ pkgs, ... }:
{
  programs.radicle = {
    enable = true;
  };

  services.radicle.node = {
    enable = true;
    lazy.enable = true;
  };

  home.packages = with pkgs; [
    radicle-desktop
  ];
}

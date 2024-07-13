{ pkgs, ... }:
{
  programs.nm-applet.enable = true;

  environment.systemPackages = with pkgs; [ networkmanagerapplet ];
}

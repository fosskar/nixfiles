{ lib, ... }:
{
  # common shell settings for all machines
  environment.pathsToLink = [ "/share/zsh" ];
  programs.less.enable = lib.mkDefault true;
  programs.zsh = {
    enable = lib.mkDefault true;
    enableLsColors = lib.mkDefault true;
  };
}

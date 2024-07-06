{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    #  clock24 = true;
    #  mouse = true;
    #  escapeTime = 0;
    #  historyLimit = 10000;
    #  shell = "${pkgs.zsh}/bin/zsh";
    #  plugins = with pkgs.tmuxPlugins; [ yank ];
  };
}

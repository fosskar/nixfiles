{
  flake.modules.nixos.base =
    { lib, pkgs, ... }:
    {
      # common shell settings for all machines
      users.defaultUserShell = pkgs.zsh;
      environment.pathsToLink = [ "/share/zsh" ];
      programs.less.enable = lib.mkDefault true;
      programs.zsh.enable = lib.mkDefault true;
    };
}

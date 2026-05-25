{
  lib,
  pkgs,
  self,
  mylib,
  ...
}:
{
  home-manager.users.workspace = {
    imports = [
      self.modules.homeManager.bash
      self.modules.homeManager.bat
      self.modules.homeManager.btop
      self.modules.homeManager.dircolors
      self.modules.homeManager.direnv
      self.modules.homeManager.fish
      self.modules.homeManager.fzf
      self.modules.homeManager.neovim
      self.modules.homeManager.ripgrep
      self.modules.homeManager.shellAliases
      self.modules.homeManager.shellIntegration
      self.modules.homeManager.theme
      self.modules.homeManager.starship
      self.modules.homeManager.yazi
      self.modules.homeManager.zellij
    ]
    ++ mylib.scanPaths ./. { };

    home = {
      username = "workspace";
      homeDirectory = "/home/workspace";
      sessionVariables = {
        SHELL = "${lib.getExe pkgs.fish}";
        BROWSER = "zen";
        EDITOR = "${lib.getExe pkgs.neovim}";
      };

      stateVersion = "25.11";
    };

    systemd.user.startServices = "sd-switch";
    nix.channels = { };
  };

  programs.fish.enable = true;
  users.users.workspace.shell = pkgs.fish;
}

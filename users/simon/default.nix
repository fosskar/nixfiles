{
  lib,
  pkgs,
  self,
  mylib,
  ...
}:
{
  home-manager.users.simon = {
    imports = [
      # inputs.self.modules.homeManager.hyprland
      self.modules.homeManager.bash
      self.modules.homeManager.bat
      self.modules.homeManager.btop
      self.modules.homeManager.cliProxyApi
      self.modules.homeManager.dircolors
      self.modules.homeManager.direnv
      self.modules.homeManager.editorconfig
      self.modules.homeManager.fzf
      self.modules.homeManager.hunk
      self.modules.homeManager.neovim
      self.modules.homeManager.nixIndex
      self.modules.homeManager.ripgrep
      self.modules.homeManager.shellIntegration
      self.modules.homeManager.tmux
      self.modules.homeManager.warpTerminal
    ]
    ++ mylib.scanPaths ./. { };

    config = {
      home = {
        username = "simon";
        homeDirectory = "/home/simon";
        stateVersion = "25.11";
        sessionVariables = {
          SHELL = "${lib.getExe pkgs.fish}";
          TERMINAL = "${lib.getExe pkgs.ghostty}";
          BROWSER = "zen";
          VISUAL = "${lib.getExe pkgs.zed-editor}";
          EDITOR = "${lib.getExe pkgs.neovim}";
          KUBE_EDITOR = "${lib.getExe pkgs.neovim}";
        };
      };
      systemd.user.startServices = "sd-switch";
      nix.channels = { };
    };
  };
}

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
      self.modules.homeManager.hunk
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

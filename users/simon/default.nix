{
  lib,
  pkgs,
  mylib,
  ...
}:
{
  home-manager.users.simon = {
    imports = mylib.scanPaths ./. { };

    home = {
      username = "simon";
      homeDirectory = "/home/simon";
      stateVersion = "24.11";
      sessionVariables = {
        SHELL = "${lib.getExe pkgs.fish}";
        TERMINAL = "${lib.getExe pkgs.ghostty}";
        BROWSER = "zen";
        EDITOR = "${lib.getExe pkgs.zed-editor}";
        KUBE_EDITOR = "${lib.getExe pkgs.neovim}";
      };
    };

    systemd.user.startServices = "sd-switch";
  };
}

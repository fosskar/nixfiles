{
  lib,
  pkgs,
  mylib,
  ...
}:
{
  imports = mylib.scanPaths ./. {
    exclude = [
      "home.nix" # exclude self
    ];
  };

  home = {
    username = "simon";
    homeDirectory = "/home/simon";
    sessionVariables = {
      SHELL = "${lib.getExe pkgs.fish}";
      TERMINAL = "${lib.getExe pkgs.ghostty}";
      BROWSER = "zen";
      EDITOR = "${lib.getExe pkgs.zed-editor}";
      KUBE_EDITOR = "${lib.getExe pkgs.neovim}";
    };
    stateVersion = "23.11";
  };

  systemd.user.startServices = "sd-switch";
}

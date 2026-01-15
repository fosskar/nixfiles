{
  lib,
  pkgs,
  mylib,
  ...
}:
{
  home-manager.users.simon = {
    imports = mylib.scanPaths ./. { };

    options.nixfiles = {
      machineType = lib.mkOption {
        type = lib.types.enum [
          "desktop"
          "laptop"
        ];
        description = "machine type (desktop or laptop)";
      };

      quickshell = lib.mkOption {
        type = lib.types.enum [
          "dms"
          "noctalia"
          "none"
        ];
        default = "noctalia";
        description = "quickshell-based shell for desktop widgets";
      };
    };

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

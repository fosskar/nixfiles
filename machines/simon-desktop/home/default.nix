{
  config,
  lib,
  inputs,
  pkgs,
  mylib,
  ...
}:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager = {
    verbose = true;
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension =
      "backup-"
      + pkgs.lib.readFile "${pkgs.runCommand "timestamp" { } "echo -n `date '+%Y%m%d%H%M%S'` > $out"}";

    #users.simon.imports = [ ./simon.nix ];

    users.simon = {
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

    extraSpecialArgs = {
      inherit inputs mylib;
    };

    sharedModules = [
      {
        nix.package = lib.mkForce config.nix.package;
        programs.home-manager.enable = true;

        manual = {
          manpages.enable = false;
          html.enable = false;
          json.enable = false;
        };
        programs = {
          man.enable = false;
          man.package = null;
        };
      }
    ];
  };
}

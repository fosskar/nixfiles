{
  config,
  lib,
  inputs,
  pkgs,
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

    extraSpecialArgs = {
      inherit inputs;
      mylib = import "${inputs.self}/lib" {
        inherit lib;
        inherit (inputs) self;
      };
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
        programs.man.enable = true;
      }
    ];
  };
}

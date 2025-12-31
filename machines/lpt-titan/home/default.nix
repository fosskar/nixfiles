{
  config,
  lib,
  inputs,
  mylib,
  ...
}:
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  home-manager = {
    verbose = false;
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm.old";
    users.simon.imports = [ ./simon/home.nix ];

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
      }
    ];
  };
}

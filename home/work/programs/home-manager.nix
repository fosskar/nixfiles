{inputs, ...}: {
  programs.home-manager.enable = true;

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    sharedModules = [
      inputs.sops-nix.homeManagerModules.sops
    ];
    backupFileExtension = "backup";
  };
}

{
  flake.modules.nixos.lutris =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        (pkgs.lutris.override {
          extraPkgs = pkgs: [ pkgs.wineWowPackages.stable ];
        })
      ];
    };
}

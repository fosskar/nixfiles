{
  flake.modules.nixos.lanzaboote =
    {
      lib,
      pkgs,
      inputs,
      ...
    }:
    let
      pkiBundle = "/var/lib/sbctl";
    in
    {
      imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];

      boot = {
        loader = {
          efi.canTouchEfiVariables = lib.mkDefault true;
          systemd-boot = {
            enable = lib.mkForce false;
            configurationLimit = lib.mkDefault 20;
            consoleMode = lib.mkDefault "max";
            editor = lib.mkDefault false;
          };
        };
        lanzaboote = {
          enable = true;
          inherit pkiBundle;
        };
      };

      environment.systemPackages = [ pkgs.sbctl ];

    };
}

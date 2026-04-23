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
        loader.systemd-boot.enable = lib.mkForce false;
        bootspec.enable = true;
        lanzaboote = {
          enable = true;
          inherit pkiBundle;
        };
      };

      environment.systemPackages = [ pkgs.sbctl ];

      # persist secure boot keys
      preservation.preserveAt."/persist".directories = [ pkiBundle ];
    };
}

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
          # firmware updates (e.g. Framework BIOS) wipe enrolled secure boot
          # keys, dropping firmware to setup mode; systemd-boot then re-enrolls
          # the staged keys automatically instead of failing to boot.
          autoEnrollKeys.enable = true;
        };
      };

      environment.systemPackages = [ pkgs.sbctl ];

    };
}

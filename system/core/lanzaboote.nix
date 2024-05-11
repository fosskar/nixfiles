{
  pkgs,
  lib,
  inputs,
  ...
}: {
  imports = [
    inputs.lanzaboote.nixosModules.lanzaboote
  ];

  boot = {
    lanzaboote = {
      enable = true;
      pkiBundle = "/etc/secureboot";
    };

    loader.systemd-boot.enable = lib.mkForce false;
  };

  environment.systemPackages = [pkgs.sbctl];
}

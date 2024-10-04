{
  config,
  pkgs,
  lib,
  modulesPath,
  ...
}:
{
  imports = [
    # This module creates a bootable ISO image containing the given NixOS
    # configuration.  The derivation for the ISO image will be placed in
    # config.system.build.isoImage.
    "${modulesPath}/installer/cd-dvd/iso-image.nix"
    "${modulesPath}/installer/cd-dvd/channel.nix"
    ../hosts/desktop/configuration.nix
  ];

  isoImage = {
    isoName = "${config.isoImage.isoBaseName}-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}.iso";
    makeEfiBootable = true;
    makeUsbBootable = true;
    appendToMenuLabel = " live";
    squashfsCompression = lib.mkDefault "zstd";
  };
}

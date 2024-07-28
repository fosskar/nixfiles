{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib.lists) filter;
  inherit (lib.strings) hasSuffix;
  inherit (lib.filesystem) listFilesRecursive;

  # Get hostname from meta module.
  inherit (config.networking) hostName;

  # Call the custom Xanmod package. Any future kernel builds from different sources
  # should be added in the packages directory.
  inherit (pkgs.callPackage ./xanmod.nix { inherit hostName; }) xanmod_custom;
in
{
  # Autodiscover Nix files containing patch configurations
  # with patchfiles or extraStructuredConfig. This is not the
  # most optimized way to do it, but it works.
  imports = [ ./config ];

  # use custom Xanmod kernel
  boot.kernelPackages = pkgs.linuxPackagesFor xanmod_custom;
}

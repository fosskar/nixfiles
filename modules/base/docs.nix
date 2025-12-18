{ lib, ... }:
{
  # common documentation settings for all machines
  documentation = {
    enable = lib.mkDefault false;
    doc.enable = lib.mkDefault false;
    info.enable = lib.mkDefault false;
    nixos.enable = lib.mkDefault false;
    man.mandoc.enable = lib.mkDefault false;
    # low priority so fish.nix can override if needed
    man.generateCaches = false;
  };
}

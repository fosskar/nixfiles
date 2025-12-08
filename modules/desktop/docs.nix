{ lib, ... }:
{
  # desktop users need man pages
  documentation = {
    enable = lib.mkDefault false;
    doc.enable = lib.mkDefault false;
    info.enable = lib.mkDefault false;
    nixos.enable = lib.mkDefault false;
    man = {
      enable = lib.mkDefault true;
      generateCaches = lib.mkOverride 1500 false;
      mandoc.enable = lib.mkDefault false;
    };
  };
}

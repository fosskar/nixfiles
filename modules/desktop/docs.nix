{ lib, ... }:
{
  # desktop users need man pages
  documentation.man = {
    enable = lib.mkDefault true;
    generateCaches = lib.mkOverride 1500 false;
  };
}

{ lib, ... }:
{
  # desktop users need man pages
  documentation.man.enable = lib.mkDefault true;
}

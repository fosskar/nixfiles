{ lib, ... }:
{
  environment.stub-ld.enable = lib.mkDefault true;
}

{ lib, ... }:
{
  environment.stub-ld.enable = lib.mkDefault false;
}

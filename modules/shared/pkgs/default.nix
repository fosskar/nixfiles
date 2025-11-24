{ lib, ... }:
{
  environment = {
    defaultPackages = lib.mkForce [ ]; # no extra default packages are installed
  };
}

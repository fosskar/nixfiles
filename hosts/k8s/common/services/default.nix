{
  lib,
  ...
}:
let
  inherit (lib) mkDefault;
in
{
  imports = [
    #./cockpit.nix
    ./open-iscsi.nix
  ];

  services = {
    logrotate.enable = mkDefault false;
    udisks2.enable = mkDefault false;
  };
}

{ lib, ... }:
let
  inherit (lib) mkDefault;
in
{
  # servers don't need documentation - minimize closure size
  documentation = {
    enable = mkDefault false;
    doc.enable = mkDefault false;
    info.enable = mkDefault false;
    nixos.enable = mkDefault false;
    man = {
      enable = mkDefault false;
      generateCaches = mkDefault false;
      mandoc.enable = mkDefault false;
    };
  };
}

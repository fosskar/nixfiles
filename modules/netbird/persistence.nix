{ config, lib, options, ... }:
let
  hasPersistence = lib.hasAttrByPath [ "nixfiles" "persistence" "enable" ] options;
in
{
  config = lib.mkIf (config.services.netbird.enable or false) {
    nixfiles = lib.optionalAttrs hasPersistence {
      persistence.directories = lib.mkIf config.nixfiles.persistence.enable [
        "/var/lib/netbird"
      ];
    };
  };
}

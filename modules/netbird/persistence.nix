{ config, lib, ... }:
{
  config = lib.mkIf (config.services.netbird.enable or false) {
    nixfiles.persistence.directories = lib.mkIf config.nixfiles.persistence.enable [
      "/var/lib/netbird"
    ];
  };
}

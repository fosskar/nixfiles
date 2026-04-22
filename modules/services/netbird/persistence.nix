{
  flake.modules.nixos.netbirdPersistence =
    {
      config,
      lib,
      options,
      ...
    }:
    let
      hasPreservation = lib.hasAttrByPath [ "nixfiles" "preservation" "directories" ] options;
    in
    {
      config = lib.mkIf (config.services.netbird.enable or false) {
        nixfiles = lib.optionalAttrs hasPreservation {
          preservation.directories = [
            "/var/lib/netbird"
          ];
        };
      };
    };
}

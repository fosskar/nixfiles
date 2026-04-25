{
  flake.modules.nixos.netbirdPersistence =
    {
      config,
      lib,
      options,
      ...
    }:
    let
      hasPreservation = lib.hasAttrByPath [ "preservation" "preserveAt" ] options;
    in
    {
      config = lib.optionalAttrs hasPreservation {
        preservation.preserveAt."/persist".directories =
          lib.mkIf (config.services.netbird.enable or false)
            [
              "/var/lib/netbird"
            ];
      };
    };
}

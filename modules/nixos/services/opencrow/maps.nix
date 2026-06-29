{
  flake.modules.nixos.opencrow =
    {
      inputs,
      pkgs,
      ...
    }:
    let
      osm-maps =
        pkgs.runCommand "osm-maps"
          {
            nativeBuildInputs = [ pkgs.makeWrapper ];
          }
          ''
            mkdir -p $out/libexec $out/bin
            cp ${inputs.hermes-agent}/skills/productivity/maps/scripts/maps_client.py $out/libexec/maps_client.py
            makeWrapper ${pkgs.python3}/bin/python3 $out/bin/osm-maps \
              --add-flags $out/libexec/maps_client.py
          '';
    in
    {
      services.opencrow = {
        skills.maps = ./skills/maps;
        extraPackages = [ osm-maps ];
      };
    };
}

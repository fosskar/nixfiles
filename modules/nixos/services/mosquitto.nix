{
  flake.modules.nixos.mosquitto =
    { config, ... }:
    let
      vars = config.clan.core.vars.generators.mosquitto.files;
      user = name: {
        passwordFile = vars."${name}-password".path;
        acl = [ "readwrite #" ];
      };
    in
    {
      # passwords carried over from the haos mosquitto app; devices and the
      # restored mqtt integration keep their credentials
      clan.core.vars.generators.mosquitto = {
        prompts = {
          homeassistant-password = {
            description = "mosquitto password of user homeassistant";
            type = "hidden";
            persist = true;
          };
          addons-password = {
            description = "mosquitto password of user addons (zigbee2mqtt)";
            type = "hidden";
            persist = true;
          };
          tasmota-password = {
            description = "mosquitto password of user tasmota";
            type = "hidden";
            persist = true;
          };
        };
        files = {
          homeassistant-password = { };
          addons-password = { };
          tasmota-password = { };
        };
        script = ''
          cp "$prompts/homeassistant-password" "$out/homeassistant-password"
          cp "$prompts/addons-password" "$out/addons-password"
          cp "$prompts/tasmota-password" "$out/tasmota-password"
        '';
      };

      services.mosquitto = {
        enable = true;
        listeners = [
          {
            users = {
              homeassistant = user "homeassistant";
              addons = user "addons";
              tasmota = user "tasmota";
            };
          }
        ];
      };

      # tasmota devices on the iot network reach the broker (router rule iot_mqtt)
      networking.firewall.allowedTCPPorts = [ 1883 ];

      # the restored mqtt integration and old clients address the broker as on haos
      networking.hosts."127.0.0.1" = [ "core-mosquitto" ];
    };
}

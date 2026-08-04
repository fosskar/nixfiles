_: {
  flake.modules.nixos.hermesHomeAssistant =
    { config, lib, ... }:
    let
      inherit (config.services.hermes-agent.homeAssistant) url;
    in
    {
      options.services.hermes-agent.homeAssistant.url = lib.mkOption {
        type = lib.types.str;
        example = "http://homeassistant.lan:8123";
      };

      config.systemd.services = {
        hermes-agent.environment.HASS_URL = url;
        hermes-dashboard.environment.HASS_URL = url;
      };
    };
}

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

      # left hermes core; installed here so hermes does not try at runtime
      config.services.hermes-agent.catalogPlugins = [ "homeassistant" ];

      config.services.hermes-agent.managed.environment.HASS_URL = url;
    };
}

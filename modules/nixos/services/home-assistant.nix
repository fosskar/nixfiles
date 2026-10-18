{
  flake.modules.nixos.homeAssistant =
    { pkgs, ... }:
    {
      services.home-assistant = {
        enable = true;

        # integrations configured in the ui; each needs its python dependencies here
        extraComponents = [
          # onboarding defaults
          "default_config"
          "met"
          "esphome"

          "adguard"
          "analytics"
          "androidtv_remote"
          "apple_tv"
          "cast"
          "go2rtc"
          "homeassistant_sky_connect"
          # ignored printer discoveries still load its config flow
          "ipp"
          "mobile_app"
          "mqtt"
          "nina"
          "openweathermap"
          "roborock"
          "sun"
          "tasmota"
          "trmnl"
          "webdav"
          "wyoming"
        ];

        customComponents = [ pkgs.home-assistant-custom-components.roborock_custom_map ];

        customLovelaceModules = [
          pkgs.home-assistant-custom-lovelace-modules.bubble-card
          pkgs.home-assistant-custom-lovelace-modules.clock-weather-card
          pkgs.home-assistant-custom-lovelace-modules.mini-graph-card
          pkgs.home-assistant-custom-lovelace-modules.xiaomi-vacuum-map-card
        ];

        config = {
          default_config = { };
          frontend.themes = "!include_dir_merge_named themes";
          automation = "!include automations.yaml";
          script = "!include scripts.yaml";
          scene = "!include scenes.yaml";
          http = {
            use_x_forwarded_for = true;
            trusted_proxies = [ "127.0.0.1" ];
          };
          homeassistant.allowlist_external_urls = [ "https://pangolin.simonoscar.me" ];
        };
      };

      # configuration.yaml includes these; ui edits write to them
      systemd.tmpfiles.rules = [
        "f /var/lib/hass/automations.yaml 0644 hass hass"
        "f /var/lib/hass/scripts.yaml 0644 hass hass"
        "f /var/lib/hass/scenes.yaml 0644 hass hass"
      ];

      # lan clients and the srv network (router rule srv_homeassistant) reach the frontend directly
      networking.firewall.allowedTCPPorts = [ 8123 ];
    };
}

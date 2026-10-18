let
  port = 8123;
in
{
  flake.modules.nixos.homeAssistant =
    { flake-self, pkgs, ... }:
    let
      localHost = "ha.${flake-self.domains.local}";
    in
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
          # enabled in the ui (config entry only); serves /api/mcp
          "mcp_server"
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
            # caddy on nixbox (${localHost}) and the netbird proxy (public domain)
            trusted_proxies = [
              "127.0.0.1"
              flake-self.hosts.nixbox.lan
              "100.64.0.0/10"
            ];
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
      networking.firewall.allowedTCPPorts = [ port ];

      services.homepage-dashboard.services = [
        {
          "apps" = [
            {
              "Home Assistant" = {
                href = "https://${localHost}";
                icon = "home-assistant.svg";
                siteMonitor = "https://${localHost}";
              };
            }
          ];
        }
      ];

      services.gatus.settings.endpoints = [
        {
          name = "home assistant";
          url = "https://${localHost}/";
          enabled = true;
          alerts = [ { type = "matrix"; } ];
          interval = "5m";
          conditions = [ "[STATUS] == 200" ];
        }
      ];
    };

  # caddy runs on nixbox; the router lets the srv network reach home assistant (srv_homeassistant)
  flake.modules.nixos.homeAssistantProxy =
    { flake-self, ... }:
    {
      services.caddy.virtualHosts."ha.${flake-self.domains.local}".extraConfig = ''
        reverse_proxy http://${flake-self.hosts.ha-green.lan}:${toString port}
      '';
    };
}

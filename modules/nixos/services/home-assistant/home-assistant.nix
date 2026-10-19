let
  port = 8123;
in
{
  flake.modules.nixos.homeAssistant =
    {
      config,
      flake-self,
      lib,
      pkgs,
      ...
    }:
    let
      localHost = "ha.${flake-self.domains.local}";
      configDir = config.services.home-assistant.configDir;
      yaml = pkgs.formats.yaml { };
      # url path -> dashboard; contents in ./_dashboards
      dashboards = {
        dashboard-home = {
          title = "Home-Server";
          icon = "mdi:server";
          file = ./_dashboards/home-server.nix;
        };
        dashboard-roboclean = {
          title = "RoboClean";
          icon = "mdi:robot-mower";
          file = ./_dashboards/roboclean.nix;
        };
        dashboard-weather = {
          title = "Weather";
          icon = "mdi:weather-cloudy";
          file = ./_dashboards/weather.nix;
        };
        internet-security = {
          title = "Internet Security";
          icon = "mdi:shield-check";
          require_admin = true;
          file = ./_dashboards/internet-security.nix;
        };
      };
    in
    {
      services.home-assistant = {
        enable = true;

        # integrations configured in the ui whose python dependencies default_config
        # does not already pull in
        extraComponents = [
          "default_config"
          "met"
          "adguard"
          "androidtv_remote"
          "apple_tv"
          "cast"
          # default_config covers its python dependencies; listing it adds the go2rtc binary
          "go2rtc"
          "homeassistant_sky_connect"
          # the printer's ignored discovery still loads the ipp config flow, which needs pyipp
          "ipp"
          # conversation agent on the llama-cpp server (https://llama-cpp.<local domain>/v1)
          "llama_cpp"
          # enabled in the ui (config entry only); serves /api/mcp
          "mcp_server"
          "mqtt"
          "nina"
          "openweathermap"
          "roborock"
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
          # the module copies time.timeZone (UTC on servers) here, which also locks the
          # general settings in the ui; keep the time zone managed in the ui
          homeassistant.time_zone = null;
          frontend.themes = "!include_dir_merge_named themes";
          lovelace.dashboards = lib.mapAttrs (
            name: dashboard:
            removeAttrs dashboard [ "file" ]
            // {
              mode = "yaml";
              filename = "dashboards/${name}.yaml";
            }
          ) dashboards;
          automation = [
            {
              id = "hue_dimmer_hue_button_plug";
              alias = "hue dimmer v2 - hue button toggles plug";
              description = "bottom hue button toggles smart plug";
              triggers =
                map
                  (subtype: {
                    trigger = "device";
                    domain = "mqtt";
                    device_id = "84ea6631a07c5a8cbce000de01f25349";
                    type = "action";
                    inherit subtype;
                  })
                  [
                    "recall_0"
                    "recall_1"
                  ];
              actions = [
                {
                  action = "switch.toggle";
                  target.entity_id = "switch.hue_smart_plug_philips";
                }
              ];
            }
          ];
          # no http: home assistant migrates it to .storage/http once and ignores yaml
          # afterwards; trusted proxies (caddy on nixbox, the netbird proxy) live there
        };
      };

      systemd.tmpfiles.rules = [
        "d ${configDir}/dashboards 0750 hass hass"
      ]
      ++ lib.mapAttrsToList (
        name: dashboard:
        "L+ ${configDir}/dashboards/${name}.yaml - - - - ${yaml.generate "${name}.yaml" (import dashboard.file)}"
      ) dashboards;

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

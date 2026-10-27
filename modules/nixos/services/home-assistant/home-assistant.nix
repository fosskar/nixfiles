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
      # id -> temperature and humidity sensor prefix; feeds the ventilation hint on the climate dashboard
      humidityPlaces = {
        outdoor = "sensor.openweathermap";
        living_room = "sensor.temperature_and_humidity_sensor_aqara_living_room";
        bedroom = "sensor.temperature_and_humidity_sensor_aqara_bed_room";
        office = "sensor.temperature_and_humidity_sensor_aqara_office";
      };
      title = id: lib.concatMapStringsSep " " lib.toSentenceCase (lib.splitString "_" id);
      # url path -> dashboard; contents in ./_dashboards
      dashboards = {
        dashboard-overview = {
          title = "Overview";
          icon = "mdi:home";
          file = ./_dashboards/overview.nix;
        };
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
        dashboard-climate = {
          title = "Climate";
          icon = "mdi:home-thermometer";
          file = ./_dashboards/climate.nix;
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
          # radicale through the opencloud proxy; log in with an opencloud app token
          "caldav"
          "cast"
          # default_config covers its python dependencies; listing it adds the go2rtc binary
          "go2rtc"
          "homeassistant_sky_connect"
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

        customComponents = [
          pkgs.home-assistant-custom-components.roborock_custom_map
          pkgs.home-assistant-custom-components.auth_oidc
        ];

        customLovelaceModules = [
          pkgs.home-assistant-custom-lovelace-modules.bubble-card
          pkgs.home-assistant-custom-lovelace-modules.button-card
          pkgs.home-assistant-custom-lovelace-modules.mini-graph-card
          pkgs.home-assistant-custom-lovelace-modules.weather-radar-card
          pkgs.home-assistant-custom-lovelace-modules.xiaomi-vacuum-map-card
        ];

        config = {
          default_config = { };
          # the module copies time.timeZone (UTC on servers) here, which also locks the
          # general settings in the ui; keep the time zone managed in the ui
          homeassistant.time_zone = null;
          frontend.themes = "!include_dir_merge_named themes";
          # client registered with authelia in homeAssistantProxy
          auth_oidc = {
            client_id = "home-assistant";
            discovery_url = "https://auth.${flake-self.domains.public}/.well-known/openid-configuration";
            display_name = "Authelia";
            # the component defaults to the authentik group "admins"
            roles = {
              admin = "admin";
              user = "user";
            };
          };
          lovelace.dashboards = lib.mapAttrs (
            name: dashboard:
            removeAttrs dashboard [ "file" ]
            // {
              mode = "yaml";
              filename = "dashboards/${name}.yaml";
            }
          ) dashboards;
          template = [
            {
              # magnus formula: water vapour in g/m³ from temperature and relative humidity
              sensor = lib.mapAttrsToList (id: prefix: {
                name = "${title id} Absolute Humidity";
                unique_id = "${id}_absolute_humidity";
                default_entity_id = "sensor.${id}_absolute_humidity";
                device_class = "absolute_humidity";
                state_class = "measurement";
                unit_of_measurement = "g/m³";
                availability = "{{ has_value('${prefix}_temperature') and has_value('${prefix}_humidity') }}";
                state = ''
                  {% set t = states('${prefix}_temperature') | float %}
                  {% set rh = states('${prefix}_humidity') | float %}
                  {{ (6.112 * e ** (17.67 * t / (t + 243.5)) * rh * 2.1674 / (273.15 + t)) | round(1) }}
                '';
              }) humidityPlaces;
              # opening the windows dries a room when the outdoor air holds at least 1 g/m³ less water
              binary_sensor = lib.mapAttrsToList (id: _: {
                name = "${title id} Ventilate";
                unique_id = "${id}_ventilate";
                default_entity_id = "binary_sensor.${id}_ventilate";
                icon = "mdi:window-open-variant";
                availability = "{{ has_value('sensor.outdoor_absolute_humidity') and has_value('sensor.${id}_absolute_humidity') }}";
                state = "{{ states('sensor.outdoor_absolute_humidity') | float < states('sensor.${id}_absolute_humidity') | float - 1 }}";
              }) (removeAttrs humidityPlaces [ "outdoor" ]);
            }
            {
              # forecasts are no longer state attributes; fetch them for the weather dashboard
              triggers = [
                {
                  trigger = "time_pattern";
                  minutes = "/15";
                }
                {
                  trigger = "homeassistant";
                  event = "start";
                }
              ];
              actions = [
                {
                  action = "weather.get_forecasts";
                  target.entity_id = "weather.forecast_home";
                  data.type = "hourly";
                  response_variable = "hourly";
                }
                {
                  action = "weather.get_forecasts";
                  target.entity_id = "weather.forecast_home";
                  data.type = "daily";
                  response_variable = "daily";
                }
              ];
              sensor = [
                {
                  name = "Rain Outlook";
                  unique_id = "rain_outlook";
                  default_entity_id = "sensor.rain_outlook";
                  icon = "mdi:weather-rainy";
                  state = ''
                    {% set ns = namespace(start=none, stop=none, total=0, kind='Rain') %}
                    {% for f in hourly['weather.forecast_home'].forecast[:12] %}
                      {% set mm = f.precipitation | float(0) %}
                      {% if mm >= 0.1 %}
                        {% if ns.start is none %}
                          {% set ns.start = f.datetime %}
                          {% set ns.kind = 'Snow' if f.condition in ['snowy', 'snowy-rainy'] else 'Rain' %}
                        {% endif %}
                        {% if ns.stop is none %}{% set ns.total = ns.total + mm %}{% endif %}
                      {% elif ns.start is not none and ns.stop is none %}
                        {% set ns.stop = f.datetime %}
                      {% endif %}
                    {% endfor %}
                    {% if ns.start is none %}
                      No rain in the next 12 hours
                    {% else %}
                      {% set start = as_datetime(ns.start) %}
                      {% set amount = ns.total | round(1) ~ ' mm' %}
                      {% if start <= now() %}
                        {{ ns.kind }} {{ 'until ' ~ as_local(as_datetime(ns.stop)).strftime('%H:%M') if ns.stop else 'for the next 12 hours' }}, {{ amount }}
                      {% else %}
                        {% set hours = ((start - now()).total_seconds() / 3600) | round(0) | int %}
                        {{ ns.kind }} from {{ as_local(start).strftime('%H:%M') }}, {{ 'in ' ~ hours ~ ' h' if hours >= 1 else 'within the hour' }}, {{ amount }}
                      {% endif %}
                    {% endif %}
                  '';
                  attributes = {
                    high = "{{ daily['weather.forecast_home'].forecast[0].temperature }}";
                    low = "{{ daily['weather.forecast_home'].forecast[0].templow }}";
                  };
                }
              ];
            }
          ];
          # quick actions on the overview dashboard
          script = {
            leaving = {
              alias = "Leaving";
              icon = "mdi:door-open";
              sequence = [
                {
                  action = "light.turn_off";
                  target.entity_id = "all";
                }
                {
                  action = "vacuum.start";
                  target.entity_id = "vacuum.roborock_qv_35a";
                }
              ];
            };
            pause_adguard = {
              alias = "Pause AdGuard for 10 minutes";
              icon = "mdi:timer-pause-outline";
              # a second tap restarts the 10 minutes
              mode = "restart";
              sequence = [
                {
                  action = "switch.turn_off";
                  target.entity_id = "switch.adguard_home_protection";
                }
                { delay.minutes = 10; }
                {
                  action = "switch.turn_on";
                  target.entity_id = "switch.adguard_home_protection";
                }
              ];
            };
            pause_heating = {
              alias = "Pause heating for 5 minutes";
              icon = "mdi:window-open-variant";
              # one run per thermostat; a second tap reads the paused "off" and stops at the condition
              mode = "parallel";
              fields.thermostat = {
                description = "climate entity to pause";
                required = true;
                selector.entity.domain = "climate";
              };
              variables.previous = "{{ states(thermostat) }}";
              sequence = [
                {
                  condition = "template";
                  value_template = "{{ previous in ['heat', 'auto'] }}";
                }
                {
                  action = "climate.set_hvac_mode";
                  target.entity_id = "{{ thermostat }}";
                  data.hvac_mode = "off";
                }
                { delay.minutes = 5; }
                {
                  action = "climate.set_hvac_mode";
                  target.entity_id = "{{ thermostat }}";
                  data.hvac_mode = "{{ previous }}";
                }
              ];
            };
          };
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
            (
              let
                sensors = map (id: "binary_sensor.${id}_ventilate") (
                  lib.attrNames (removeAttrs humidityPlaces [ "outdoor" ])
                );
                rooms = "${builtins.toJSON sensors} | select('is_state', 'on') | map('state_attr', 'friendly_name') | map('replace', ' Ventilate', '') | list";
              in
              {
                id = "ventilation_notify";
                alias = "ventilation - let some fresh air in";
                description = "push to all phones when a room's ventilate sensor turns on; quiet 22:00-08:00";
                # the 08:00 trigger reports rooms that turned on during the quiet hours
                triggers =
                  map (entity_id: {
                    trigger = "state";
                    inherit entity_id;
                    to = "on";
                    for.minutes = 15;
                  }) sensors
                  ++ [
                    {
                      trigger = "time";
                      at = "08:00:00";
                    }
                  ];
                conditions = [
                  {
                    condition = "time";
                    after = "08:00:00";
                    before = "22:00:00";
                  }
                  {
                    condition = "template";
                    value_template = "{{ (${rooms}) | count > 0 }}";
                  }
                  # at most one push per 3 hours when a sensor flaps around the 1 g/m³ threshold
                  {
                    condition = "template";
                    value_template = "{{ this.attributes.last_triggered is none or now() - this.attributes.last_triggered > timedelta(hours=3) }}";
                  }
                ];
                actions =
                  map
                    (action: {
                      inherit action;
                      data = {
                        title = "Let some fresh air in";
                        message = "Humid air in {{ (${rooms}) | join(', ') }}";
                      };
                    })
                    [
                      "notify.mobile_app_pixel_9"
                      "notify.mobile_app_ipad_von_anna"
                    ];
              }
            )
          ]
          ++
            map
              (
                room:
                let
                  sensor = "sensor.temperature_and_humidity_sensor_aqara_${room}_temperature";
                  trv = "thermostat_${room}_sonoff";
                  source = "select.${trv}_temperature_sensor_select";
                in
                {
                  id = "trv_${room}_external_temperature";
                  alias = "trv ${lib.replaceStrings [ "_" ] [ " " ] room} - feed aqara temperature";
                  description = "sonoff trvzb regulates on the aqara room sensor instead of its radiator-side sensor; forces remote_temperature";
                  triggers = [
                    {
                      trigger = "state";
                      entity_id = sensor;
                    }
                    # the aqara only reports on change; resend so the valve does not fall back to remote_source_offline
                    {
                      trigger = "time_pattern";
                      minutes = "/30";
                    }
                    # the valve resets to local_temperature after an ota update
                    {
                      trigger = "state";
                      entity_id = source;
                      not_to = [
                        "remote_temperature"
                        "unavailable"
                        "unknown"
                      ];
                    }
                  ];
                  conditions = [
                    {
                      condition = "template";
                      value_template = "{{ states('${sensor}') | is_number }}";
                    }
                  ];
                  actions = [
                    {
                      action = "number.set_value";
                      target.entity_id = "number.${trv}_external_temperature_input";
                      data.value = "{{ states('${sensor}') | float }}";
                    }
                    {
                      "if" = [
                        {
                          condition = "template";
                          value_template = "{{ states('${source}') not in ['remote_temperature', 'unavailable', 'unknown'] }}";
                        }
                      ];
                      "then" = [
                        {
                          action = "select.select_option";
                          target.entity_id = source;
                          data.option = "remote_temperature";
                        }
                      ];
                    }
                  ];
                }
              )
              [
                "living_room"
                "office"
              ]
          # no resync on state change: the valve pads its readback to 6 transitions, which never matches and loops
          ++ lib.concatLists (
            lib.mapAttrsToList
              (
                room: schedule:
                let
                  days = [
                    "monday"
                    "tuesday"
                    "wednesday"
                    "thursday"
                    "friday"
                    "saturday"
                    "sunday"
                  ];
                  entities = map (day: "text.thermostat_${room}_sonoff_weekly_schedule_${day}") days;
                  name = lib.replaceStrings [ "_" ] [ " " ] room;
                  climate = "climate.thermostat_${room}_sonoff";
                  transitions = lib.remove "00:00" (
                    map (transition: lib.head (lib.splitString "/" transition)) (lib.splitString " " schedule)
                  );
                in
                [
                  {
                    id = "trv_${room}_weekly_schedule";
                    alias = "trv ${name} - weekly schedule";
                    description = "writes the declared weekly schedule to the sonoff trvzb";
                    triggers = [
                      {
                        trigger = "homeassistant";
                        event = "start";
                      }
                    ];
                    actions = [
                      {
                        action = "text.set_value";
                        target.entity_id = entities;
                        data.value = schedule;
                      }
                    ];
                  }
                  {
                    id = "trv_${room}_resume_schedule";
                    alias = "trv ${name} - resume schedule";
                    description = "a manual change can leave the valve in heat; return it to auto at the next schedule transition";
                    triggers = map (time: {
                      trigger = "time";
                      at = "${time}:00";
                    }) transitions;
                    conditions = [
                      {
                        condition = "state";
                        entity_id = climate;
                        state = "heat";
                      }
                    ];
                    actions = [
                      {
                        action = "climate.set_hvac_mode";
                        target.entity_id = climate;
                        data.hvac_mode = "auto";
                      }
                    ];
                  }
                ]
              )
              {
                living_room = "00:00/18 06:00/20 20:00/18";
                office = "00:00/16 08:00/20 21:00/16";
              }
          );
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

  # caddy and authelia run on nixbox; the router lets the srv network reach home assistant (srv_homeassistant)
  flake.modules.nixos.homeAssistantProxy =
    { flake-self, ... }:
    let
      localHost = "ha.${flake-self.domains.local}";
    in
    {
      services.caddy.virtualHosts.${localHost}.extraConfig = ''
        reverse_proxy http://${flake-self.hosts.ha-green.lan}:${toString port}
      '';

      services.authelia.instances.main.settings.identity_providers.oidc = {
        claims_policies.home_assistant.id_token = [
          "groups"
          "preferred_username"
          "name"
        ];
        clients = [
          {
            client_id = "home-assistant";
            client_name = "Home Assistant";
            public = true;
            require_pkce = true;
            pkce_challenge_method = "S256";
            token_endpoint_auth_method = "none";
            consent_mode = "implicit";
            authorization_policy = "users";
            claims_policy = "home_assistant";
            redirect_uris = [ "https://${localHost}/auth/oidc/callback" ];
            scopes = [
              "openid"
              "profile"
              "groups"
            ];
            response_types = [ "code" ];
            grant_types = [ "authorization_code" ];
          }
        ];
      };
    };
}

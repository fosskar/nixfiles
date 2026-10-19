let
  temperatureThresholds = import ./temperature-thresholds.nix;

  rooms = [
    {
      id = "living_room";
      name = "Living Room";
      icon = "mdi:sofa";
      sensor = "sensor.temperature_and_humidity_sensor_aqara_living_room";
      light = "light.living_room_bulbs";
    }
    {
      id = "bedroom";
      name = "Bedroom";
      icon = "mdi:bed";
      sensor = "sensor.temperature_and_humidity_sensor_aqara_bed_room";
    }
    {
      id = "office";
      name = "Office";
      icon = "mdi:desk";
      sensor = "sensor.temperature_and_humidity_sensor_aqara_office";
    }
  ];

  # entity -> badge name
  batteries = {
    "sensor.temperature_and_humidity_sensor_aqara_living_room_battery" = "Living Room sensor";
    "sensor.temperature_and_humidity_sensor_aqara_bed_room_battery" = "Bedroom sensor";
    "sensor.temperature_and_humidity_sensor_aqara_office_battery" = "Office sensor";
    "sensor.hue_dimmer_switch_philips_battery" = "Hue dimmer";
  };

  vacuum = "vacuum.roborock_qv_35a";

  mediaPlayers = [
    "media_player.shield"
    "media_player.shield_3"
    "media_player.lg_tv"
    "media_player.android_airplay_android_airplay"
  ];

  energySensors = [
    "sensor.tasmota_server_energy"
    "sensor.tasmota_wan_energy"
    "sensor.tasmota_tv_energy"
  ];

  navigate = path: {
    action = "navigate";
    navigation_path = path;
  };

  perform = action: target: data: {
    action = "perform-action";
    perform_action = action;
    inherit target data;
  };

  # bubble-card name button, coloured icon, one action on the whole card
  quickAction =
    {
      name,
      icon,
      color,
      action,
      columns ? 6,
    }:
    {
      type = "custom:bubble-card";
      card_type = "button";
      button_type = "name";
      inherit name icon;
      card_layout = "large";
      button_action.tap_action = action;
      tap_action = action;
      styles = ".bubble-icon { color: ${color} !important; }";
      grid_options = {
        inherit columns;
        rows = 1;
      };
    };

  roomCard =
    room:
    let
      climate = "{{ states('${room.sensor}_temperature') }} °C · {{ states('${room.sensor}_humidity') }} %";
    in
    {
      type = "vertical-stack";
      grid_options.columns = 12;
      cards = [
        (
          {
            type = "custom:bubble-card";
            card_type = "button";
            inherit (room) name icon;
            state_content = climate;
            sub_button =
              if room.ventilate or true then
                [
                  {
                    entity = "binary_sensor.${room.id}_ventilate";
                    name = "Open window";
                    icon = "mdi:window-open-variant";
                    show_name = true;
                    tap_action = navigate "/dashboard-climate";
                    visibility = [
                      {
                        condition = "state";
                        entity = "binary_sensor.${room.id}_ventilate";
                        state = "on";
                      }
                    ];
                  }
                ]
              else
                [ ];
          }
          # the switch button fills with the light colour while the room is lit
          // (
            if room ? light then
              {
                entity = room.light;
                button_type = "switch";
                button_action.tap_action.action = "toggle";
              }
            else
              {
                entity = "${room.sensor}_temperature";
                button_type = "state";
                button_action.tap_action = navigate "/dashboard-climate";
              }
          )
        )
        {
          type = "custom:mini-graph-card";
          entities = [ "${room.sensor}_temperature" ];
          hours_to_show = 24;
          points_per_hour = 2;
          height = 60;
          line_width = 3;
          animate = true;
          color_thresholds = temperatureThresholds;
          color_thresholds_transition = "hard";
          tap_action = navigate "/dashboard-climate";
          show = {
            name = false;
            icon = false;
            state = false;
            legend = false;
            labels = false;
            extrema = false;
            fill = "fade";
          };
        }
      ];
    };

  # one sentence on the state of the flat, rendered by home assistant
  greeting = ''
    {% set h = now().hour %}
    # {{ 'Good morning' if h < 11 else 'Good afternoon' if h < 18 else 'Good evening' }}, {{ user }}
    {# light.living_room_bulbs groups the living room bulbs, which are counted on their own #}
    {% set lit = states.light | selectattr('state', 'eq', 'on') | rejectattr('entity_id', 'eq', 'light.living_room_bulbs') | list | count %}
    {% set temps = [${
      builtins.concatStringsSep ", " (map (room: "'${room.sensor}_temperature'") rooms)
    }] | map('states') | select('is_number') | map('float') | list %}
    {% set ns = namespace(vent=[]) %}
    {% for name, entity in [${
      builtins.concatStringsSep ", " (
        map (room: "('${room.name}', 'binary_sensor.${room.id}_ventilate')") rooms
      )
    }] %}{% if is_state(entity, 'on') %}{% set ns.vent = ns.vent + [name] %}{% endif %}{% endfor %}
    {{ 'All lights are off' if lit == 0 else lit ~ (' light is' if lit == 1 else ' lights are') ~ ' on' }}.
    It is {{ (temps | sum / temps | count) | round(1) if temps else '?' }} °C inside and {{ states('sensor.openweathermap_temperature') }} °C outside, {{ states('weather.forecast_home') | replace('partlycloudy', 'partly cloudy') | replace('-', ' ') }}.
    {% if ns.vent %}**Let some fresh air in:** {{ ns.vent | join(', ') }}{% endif %}
    {% if is_state('${vacuum}', 'cleaning') %}The Roborock is cleaning.{% endif %}
  '';

  badge =
    attrs:
    {
      type = "entity";
      show_name = false;
      show_state = true;
    }
    // attrs;
in
{
  views = [
    {
      type = "sections";
      title = "Overview";
      path = "overview";
      icon = "mdi:home";
      theme = "Frosted Glass Dark Lite";
      max_columns = 3;
      header = {
        layout = "responsive";
        badges_position = "bottom";
        card = {
          type = "markdown";
          text_only = true;
          content = greeting;
        };
      };
      # shown only while something needs attention
      badges =
        map (
          room:
          badge {
            entity = "binary_sensor.${room.id}_ventilate";
            name = "Ventilate ${room.name}";
            icon = "mdi:window-open-variant";
            color = "light-blue";
            show_name = true;
            show_state = false;
            tap_action = navigate "/dashboard-climate";
            visibility = [
              {
                condition = "state";
                entity = "binary_sensor.${room.id}_ventilate";
                state = "on";
              }
            ];
          }
        ) rooms
        ++ builtins.attrValues (
          builtins.mapAttrs (
            entity: name:
            badge {
              inherit entity name;
              icon = "mdi:battery-alert";
              color = "orange";
              show_name = true;
              visibility = [
                {
                  condition = "numeric_state";
                  inherit entity;
                  below = 20;
                }
              ];
            }
          ) batteries
        )
        ++ map (
          slot:
          badge {
            entity = "sensor.hamburg_freie_und_hansestadt_headline_${toString slot}";
            icon = "mdi:alert";
            color = "red";
            tap_action = navigate "/dashboard-weather";
            visibility = [
              {
                condition = "state";
                entity = "binary_sensor.nina_warning_hamburg_freie_und_hansestadt_${toString slot}";
                state = "on";
              }
            ];
          }
        ) (builtins.genList (n: n + 1) 5);
      sections = [
        {
          type = "grid";
          cards = [
            {
              type = "custom:clock-weather-card";
              entity = "weather.forecast_home";
              temperature_sensor = "sensor.openweathermap_temperature";
              humidity_sensor = "sensor.openweathermap_humidity";
              apparent_sensor = "sensor.openweathermap_feels_like_temperature";
              show_humidity = true;
              forecast_rows = 5;
              time_format = 24;
              date_pattern = "cccc, d LLLL";
              grid_options.columns = "full";
            }
          ]
          ++ map (entity: {
            type = "media-control";
            inherit entity;
            grid_options.columns = "full";
            visibility = [
              {
                condition = "state";
                inherit entity;
                state = [
                  "playing"
                  "paused"
                ];
              }
            ];
          }) mediaPlayers
          ++ [
            (quickAction {
              name = "Ask Assist";
              icon = "mdi:microphone";
              color = "#3ddc97";
              action.action = "assist";
              columns = "full";
            })
          ];
        }
        {
          type = "grid";
          column_span = 2;
          cards = [
            {
              type = "heading";
              heading = "Quick";
              icon = "mdi:lightning-bolt-outline";
            }
            (quickAction {
              name = "Evening";
              icon = "mdi:weather-sunset";
              color = "#ffb547";
              action = perform "light.turn_on" { area_id = "living_room"; } {
                brightness_pct = 40;
                color_temp_kelvin = 2700;
              };
            })
            (quickAction {
              name = "Movie";
              icon = "mdi:movie-open-outline";
              color = "#a78bfa";
              action = perform "light.turn_on" { area_id = "living_room"; } {
                brightness_pct = 10;
                color_temp_kelvin = 2200;
              };
            })
            (quickAction {
              name = "All off";
              icon = "mdi:power";
              color = "#90a4ae";
              action = perform "light.turn_off" { entity_id = "all"; } { };
            })
            (quickAction {
              name = "Leaving";
              icon = "mdi:door-open";
              color = "#4fc3f7";
              action = perform "script.turn_on" { entity_id = "script.leaving"; } { } // {
                confirmation.text = "Turn off all lights and start the Roborock?";
              };
            })
            {
              type = "heading";
              heading = "Rooms";
              icon = "mdi:floor-plan";
              tap_action = navigate "/dashboard-climate";
            }
          ]
          ++ map roomCard rooms
          ++ [
            (roomCard {
              id = "outdoor";
              name = "Outside";
              icon = "mdi:tree-outline";
              sensor = "sensor.openweathermap";
              ventilate = false;
            })
          ];
        }
        {
          type = "grid";
          cards = [
            {
              type = "heading";
              heading = "Energy";
              icon = "mdi:flash";
              tap_action = navigate "/energy";
            }
            {
              type = "custom:bubble-card";
              card_type = "button";
              button_type = "state";
              entity = "sensor.tasmota_server_energy_today";
              name = "Today";
              icon = "mdi:flash";
              state_content = "{{ ([${
                builtins.concatStringsSep ", " (map (s: "'${s}_today'") energySensors)
              }] | map('states') | map('float', 0) | sum) | round(2) }} kWh · yesterday {{ ([${
                builtins.concatStringsSep ", " (map (s: "'${s}_yesterday'") energySensors)
              }] | map('states') | map('float', 0) | sum) | round(2) }} kWh";
              button_action.tap_action = navigate "/energy";
              styles = ".bubble-icon { color: #ffb547 !important; }";
            }
            {
              type = "statistics-graph";
              entities = map (s: "${s}_total") energySensors;
              stat_types = [ "change" ];
              period = "hour";
              days_to_show = 1;
              chart_type = "bar";
              hide_legend = true;
            }
          ];
        }
        {
          type = "grid";
          cards = [
            {
              type = "heading";
              heading = "Roborock";
              icon = "mdi:robot-vacuum";
              tap_action = navigate "/dashboard-roboclean";
            }
            {
              type = "custom:bubble-card";
              card_type = "button";
              button_type = "state";
              entity = vacuum;
              name = "Roborock";
              icon = "mdi:robot-vacuum";
              state_content = [
                "state"
                "{{ states('sensor.roborock_qv_35a_battery') }} %"
              ];
              button_action.tap_action = navigate "/dashboard-roboclean";
              sub_button = [
                {
                  name = "Clean";
                  icon = "mdi:play";
                  tap_action = perform "vacuum.start" { entity_id = vacuum; } { };
                }
                {
                  name = "Dock";
                  icon = "mdi:home-import-outline";
                  tap_action = perform "vacuum.return_to_base" { entity_id = vacuum; } { };
                }
              ];
            }
            {
              type = "custom:bubble-card";
              card_type = "button";
              button_type = "state";
              entity = "sensor.roborock_qv_35a_cleaning_area";
              name = "Last run";
              icon = "mdi:map-check-outline";
              state_content = "{{ states('sensor.roborock_qv_35a_cleaning_area', with_unit=True) }} in {{ states('sensor.roborock_qv_35a_cleaning_time', with_unit=True) }}";
              button_action.tap_action = navigate "/dashboard-roboclean";
            }
          ];
        }
        {
          type = "grid";
          cards = [
            {
              type = "heading";
              heading = "Network";
              icon = "mdi:shield-check-outline";
              tap_action = navigate "/internet-security";
            }
            {
              type = "custom:bubble-card";
              card_type = "button";
              button_type = "switch";
              entity = "switch.adguard_home_protection";
              name = "AdGuard";
              icon = "mdi:shield-check";
              state_content = "{{ states('sensor.adguard_home_dns_queries_blocked_ratio', with_unit=True) }} blocked";
              button_action.tap_action = navigate "/internet-security";
              styles = "ha-card { --bubble-accent-color: #4caf50; }";
              sub_button = [
                {
                  name = "Pause 10 min";
                  icon = "mdi:timer-pause-outline";
                  show_name = true;
                  tap_action = perform "script.turn_on" { entity_id = "script.pause_adguard"; } { };
                  visibility = [
                    {
                      condition = "state";
                      entity = "switch.adguard_home_protection";
                      state = "on";
                    }
                  ];
                }
              ];
            }
            # bubble-card requires the stack to be the last card of the view
            {
              type = "custom:bubble-card";
              card_type = "horizontal-buttons-stack";
              auto_order = false;
              "1_name" = "Climate";
              "1_icon" = "mdi:home-thermometer";
              "1_link" = "/dashboard-climate";
              "2_name" = "Weather";
              "2_icon" = "mdi:weather-cloudy";
              "2_link" = "/dashboard-weather";
              "3_name" = "RoboClean";
              "3_icon" = "mdi:robot-vacuum";
              "3_link" = "/dashboard-roboclean";
              "4_name" = "Home-Server";
              "4_icon" = "mdi:server";
              "4_link" = "/dashboard-home";
              "5_name" = "Internet Security";
              "5_icon" = "mdi:shield-check";
              "5_link" = "/internet-security";
            }
          ];
        }
      ];
    }
  ];
}

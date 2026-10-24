let
  rooms = [
    {
      id = "living_room";
      name = "Living Room";
      icon = "mdi:sofa";
      sensor = "sensor.temperature_and_humidity_sensor_aqara_living_room";
      thermostat = "thermostat_living_room_sonoff";
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

  temperatureThresholds = import ./temperature-thresholds.nix;

  # below 40 % is dry air, above 60 % risks mould
  humidityThresholds = [
    {
      value = 0;
      color = "#ffa726";
    }
    {
      value = 40;
      color = "#42a5f5";
    }
    {
      value = 60;
      color = "#ef5350";
    }
  ];

  graph = {
    type = "custom:mini-graph-card";
    hours_to_show = 24;
    points_per_hour = 2;
    line_width = 3;
    font_size = 75;
    animate = true;
    color_thresholds_transition = "hard";
    grid_options.columns = 6;
    show = {
      icon = false;
      fill = "fade";
      extrema = true;
      labels = false;
    };
  };

  # daily min, mean and max from long-term statistics
  daily = title: entity: color: {
    type = "statistics-graph";
    inherit title;
    entities = [ { inherit entity color; } ];
    hide_legend = true;
    stat_types = [
      "min"
      "mean"
      "max"
    ];
    period = "day";
    days_to_show = 14;
    chart_type = "line";
  };

  roomSection = room: {
    type = "grid";
    cards = [
      {
        type = "heading";
        heading = room.name;
        inherit (room) icon;
        badges = [
          {
            type = "entity";
            entity = "${room.sensor}_battery";
          }
        ];
      }
    ]
    ++ (
      if room ? thermostat then
        [
          {
            type = "thermostat";
            entity = "climate.${room.thermostat}";
            name = "Thermostat";
            features = [
              {
                type = "climate-hvac-modes";
                hvac_modes = [
                  "heat"
                  "auto"
                  "off"
                ];
              }
            ];
          }
          {
            type = "tile";
            entity = "switch.${room.thermostat}_open_window";
            name = "Open window detection";
          }
          {
            type = "tile";
            entity = "switch.${room.thermostat}_smart_temperature_control";
            name = "Smart temperature control";
          }
        ]
      else
        [ ]
    )
    ++ [
      (
        graph
        // {
          name = "Temperature";
          decimals = 1;
          entities = [ "${room.sensor}_temperature" ];
          color_thresholds = temperatureThresholds;
        }
      )
      (
        graph
        // {
          name = "Humidity";
          decimals = 0;
          entities = [ "${room.sensor}_humidity" ];
          color_thresholds = humidityThresholds;
        }
      )
      (daily "Temperature, 14 days" "${room.sensor}_temperature" "#42a5f5")
      (daily "Humidity, 14 days" "${room.sensor}_humidity" "#26a69a")
    ];
  };

  history = heading: icon: card: {
    type = "grid";
    cards = [
      {
        type = "heading";
        inherit heading icon;
      }
      (
        {
          type = "history-graph";
        }
        // card
      )
    ];
  };
in
{
  views = [
    {
      type = "sections";
      title = "Climate";
      path = "climate";
      icon = "mdi:home-thermometer";
      theme = "Frosted Glass Dark Lite";
      max_columns = 3;
      sections = map roomSection rooms ++ [
        {
          type = "grid";
          cards = [
            {
              type = "heading";
              heading = "Ventilation";
              icon = "mdi:window-open-variant";
            }
            {
              type = "markdown";
              # binary_sensor.<room>_ventilate is on at a gap of at least 1 g/m³ (template in home-assistant.nix)
              content = ''
                ${builtins.concatStringsSep "\n" (
                  map (
                    room:
                    "{% if is_state('binary_sensor.${room.id}_ventilate', 'on') %}<ha-icon icon=\"mdi:window-open-variant\"></ha-icon> **${room.name}**: open windows{% else %}<ha-icon icon=\"mdi:window-closed-variant\"></ha-icon> **${room.name}**: keep closed{% endif %} ({{ states('sensor.${room.id}_absolute_humidity') }} g/m³)\n"
                  ) rooms
                )}
                Outside: {{ states('sensor.outdoor_absolute_humidity') }} g/m³
              '';
            }
          ];
        }
        (history "Water in the air" "mdi:water" {
          title = "g/m³, 24 h";
          hours_to_show = 24;
          entities =
            map (room: {
              entity = "sensor.${room.id}_absolute_humidity";
              inherit (room) name;
            }) rooms
            ++ [
              {
                entity = "sensor.outdoor_absolute_humidity";
                name = "Outdoor";
              }
            ];
        })
        (history "Indoor vs outdoor" "mdi:chart-line" {
          title = "°C, 48 h";
          hours_to_show = 48;
          entities =
            map (room: {
              entity = "${room.sensor}_temperature";
              inherit (room) name;
            }) rooms
            ++ [
              {
                entity = "sensor.openweathermap_temperature";
                name = "Outdoor";
              }
            ];
        })
      ];
    }
  ];
}

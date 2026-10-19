let
  rooms = [
    {
      id = "living_room";
      name = "Living Room";
      icon = "mdi:sofa";
      sensor = "sensor.temperature_and_humidity_sensor_aqara_living_room";
      color = "#ef5350";
    }
    {
      id = "bedroom";
      name = "Bedroom";
      icon = "mdi:bed";
      sensor = "sensor.temperature_and_humidity_sensor_aqara_bed_room";
      color = "#42a5f5";
    }
    {
      id = "office";
      name = "Office";
      icon = "mdi:desk";
      sensor = "sensor.temperature_and_humidity_sensor_aqara_office";
      color = "#66bb6a";
    }
  ];

  temperatureThresholds = [
    {
      value = 0;
      color = "#42a5f5";
    }
    {
      value = 18;
      color = "#26c6da";
    }
    {
      value = 19;
      color = "#66bb6a";
    }
    {
      value = 23;
      color = "#ffa726";
    }
    {
      value = 25;
      color = "#ef5350";
    }
  ];

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
      {
        type = "statistics-graph";
        title = "Daily temperature";
        entities = [ "${room.sensor}_temperature" ];
        stat_types = [
          "min"
          "mean"
          "max"
        ];
        period = "day";
        days_to_show = 14;
        chart_type = "line";
      }
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
              content = ''
                Outdoor air: **{{ states('sensor.outdoor_absolute_humidity') }} g/m³**

                ${builtins.concatStringsSep "\n" (
                  map (room: ''
                    {% if is_state('binary_sensor.${room.id}_ventilate', 'on') %}<ha-icon icon="mdi:window-open-variant"></ha-icon> **${room.name}**: open the windows{% else %}**${room.name}**: keep closed{% endif %} ({{ states('sensor.${room.id}_absolute_humidity') }} g/m³)
                  '') rooms
                )}
              '';
            }
            {
              type = "custom:mini-graph-card";
              name = "Absolute humidity";
              hours_to_show = 24;
              points_per_hour = 2;
              line_width = 2;
              font_size = 75;
              decimals = 1;
              entities =
                map (room: {
                  entity = "sensor.${room.id}_absolute_humidity";
                  inherit (room) name color;
                }) rooms
                ++ [
                  {
                    entity = "sensor.outdoor_absolute_humidity";
                    name = "Outdoor";
                    color = "#bdbdbd";
                  }
                ];
              show = {
                icon = false;
                fill = false;
                legend = true;
                labels = true;
              };
            }
          ];
        }
        {
          type = "grid";
          column_span = 2;
          cards = [
            {
              type = "heading";
              heading = "Indoor vs outdoor";
              icon = "mdi:chart-line";
            }
            {
              type = "custom:mini-graph-card";
              name = "Temperature, 48 h";
              hours_to_show = 48;
              points_per_hour = 2;
              line_width = 2;
              font_size = 75;
              decimals = 1;
              entities =
                map (room: {
                  entity = "${room.sensor}_temperature";
                  inherit (room) name color;
                }) rooms
                ++ [
                  {
                    entity = "sensor.openweathermap_temperature";
                    name = "Outdoor";
                    color = "#bdbdbd";
                  }
                ];
              show = {
                icon = false;
                fill = false;
                legend = true;
                labels = true;
              };
            }
          ];
        }
      ];
    }
  ];
}

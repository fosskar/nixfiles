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
          name = "${room.name} temperature";
          decimals = 1;
          entities = [ "${room.sensor}_temperature" ];
          color_thresholds = temperatureThresholds;
        }
      )
      (
        graph
        // {
          name = "${room.name} humidity";
          decimals = 0;
          entities = [ "${room.sensor}_humidity" ];
          color_thresholds = humidityThresholds;
        }
      )
      {
        type = "statistics-graph";
        title = "${room.name}, daily min / mean / max";
        entities = [ "${room.sensor}_temperature" ];
        hide_legend = true;
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
              # binary_sensor.<room>_ventilate turns on at a gap of 1 g/m³ (template in home-assistant.nix)
              content = ''
                Airing a room dries it only when the outdoor air carries less water than the indoor air. Relative humidity (%) cannot tell you that, because warm air holds more water than cold air. The numbers below are grams of water per m³ of air.

                | | Water in air | Advice |
                |---|---|---|
                | Outdoor | {{ states('sensor.outdoor_absolute_humidity') }} g/m³ | |
                ${builtins.concatStringsSep "\n" (
                  map (
                    room:
                    "| ${room.name} | {{ states('sensor.${room.id}_absolute_humidity') }} g/m³ | {% set gap = (states('sensor.${room.id}_absolute_humidity') | float(0) - states('sensor.outdoor_absolute_humidity') | float(0)) | round(1) %}{% if is_state('binary_sensor.${room.id}_ventilate', 'on') %}**open the windows**: outdoor air is {{ gap }} g/m³ drier{% else %}keep closed: outdoor air is not at least 1 g/m³ drier{% endif %} |"
                  ) rooms
                )}
              '';
            }
            {
              type = "custom:mini-graph-card";
              name = "Water in the air (g/m³), 24 h";
              hours_to_show = 24;
              points_per_hour = 2;
              line_width = 2;
              font_size = 75;
              decimals = 1;
              entities =
                map (room: {
                  entity = "sensor.${room.id}_absolute_humidity";
                  inherit (room) name color;
                  show_legend_state = true;
                }) rooms
                ++ [
                  {
                    entity = "sensor.outdoor_absolute_humidity";
                    name = "Outdoor";
                    color = "#bdbdbd";
                    show_legend_state = true;
                  }
                ];
              show = {
                icon = false;
                state = false;
                fill = false;
                legend = true;
                labels = true;
                labels_secondary = true;
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
              name = "Temperature, 48 h (outdoor on the right axis)";
              # mini-graph-card sets no grid size and defaults to half of the two-column section
              grid_options.columns = "full";
              hours_to_show = 48;
              points_per_hour = 2;
              line_width = 2;
              font_size = 75;
              decimals = 1;
              entities =
                map (room: {
                  entity = "${room.sensor}_temperature";
                  inherit (room) name color;
                  show_legend_state = true;
                }) rooms
                ++ [
                  {
                    entity = "sensor.openweathermap_temperature";
                    name = "Outdoor";
                    color = "#bdbdbd";
                    show_legend_state = true;
                    # own scale, so the 15 °C gap does not flatten the indoor lines
                    y_axis = "secondary";
                  }
                ];
              show = {
                icon = false;
                state = false;
                fill = false;
                legend = true;
                labels = true;
                labels_secondary = true;
              };
            }
          ];
        }
      ];
    }
  ];
}

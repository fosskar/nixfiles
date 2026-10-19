let
  tile = entity: name: icon: color: {
    type = "tile";
    inherit
      entity
      name
      icon
      color
      ;
    tap_action = {
      action = "none";
    };
  };

  graphShow = {
    name = true;
    icon = false;
    state = true;
    legend = true;
    fill = false;
    labels = true;
  };

  outdoorColor = "#ffca28";

  # one card per nina slot, shown only while that slot holds an active warning
  ninaWarning =
    slot:
    let
      sensor = field: "sensor.hamburg_freie_und_hansestadt_${field}_${toString slot}";
    in
    {
      type = "conditional";
      conditions = [
        {
          condition = "state";
          entity = "binary_sensor.nina_warning_hamburg_freie_und_hansestadt_${toString slot}";
          state = "on";
        }
      ];
      card = {
        type = "markdown";
        text_only = true;
        content = ''
          {% set severity = states('${sensor "severity"}') %}
          <ha-alert alert-type="{{ 'error' if severity in ['severe', 'extreme'] else 'warning' }}" title="{{ states('${sensor "headline"}') }}">
          {{ severity | capitalize }} · {{ states('${sensor "sender"}') }}
          </ha-alert>
        '';
      };
    };
in
{
  views = [
    {
      type = "panel";
      title = "Weather";
      path = "weather";
      icon = "mdi:weather-cloudy";
      theme = "Frosted Glass Dark Lite";
      cards = [
        {
          type = "vertical-stack";
          cards =
            map ninaWarning [
              1
              2
              3
              4
              5
            ]
            ++ [
              {
                type = "custom:clock-weather-card";
                entity = "weather.forecast_home";
              }
              {
                show_current = false;
                show_forecast = true;
                type = "weather-forecast";
                entity = "weather.forecast_home";
                forecast_type = "hourly";
                secondary_info_attribute = "humidity";
                forecast_slots = 12;
                name = "Hamburg";
              }
              {
                show_current = false;
                show_forecast = true;
                type = "weather-forecast";
                entity = "weather.forecast_home";
                forecast_type = "daily";
                forecast_slots = 7;
              }
              {
                type = "horizontal-stack";
                cards = [
                  (tile "sensor.openweathermap_temperature" "Temperature" "mdi:thermometer" "red")
                  (tile "sensor.openweathermap_feels_like_temperature" "Feels Like" "mdi:thermometer-lines" "orange")
                  (tile "sensor.openweathermap_humidity" "Humidity" "mdi:water-percent" "blue")
                  (tile "sensor.openweathermap_wind_speed" "Wind" "mdi:weather-windy" "cyan")
                  (tile "sensor.openweathermap_pressure" "Pressure" "mdi:gauge" "grey")
                  (tile "sensor.openweathermap_cloud_coverage" "Clouds" "mdi:cloud" "grey")
                ];
              }
              {
                type = "horizontal-stack";
                cards = [
                  (tile "sensor.openweathermap_wind_gust" "Gusts" "mdi:weather-windy-variant" "cyan")
                  (tile "sensor.openweathermap_wind_bearing" "Wind Direction" "mdi:compass-outline" "cyan")
                  (tile "sensor.openweathermap_precipitation_kind" "Precipitation" "mdi:weather-pouring" "blue")
                  (tile "sensor.openweathermap_uv_index" "UV Index" "mdi:sun-wireless" "purple")
                  (tile "sensor.openweathermap_dew_point" "Dew Point" "mdi:water-thermometer" "teal")
                  (tile "sensor.openweathermap_visibility" "Visibility" "mdi:eye" "grey")
                ];
              }
              {
                type = "horizontal-stack";
                cards = [
                  (tile "sensor.sun_next_dawn" "Dawn" "mdi:weather-sunset-up" "amber")
                  (tile "sensor.sun_next_rising" "Sunrise" "mdi:weather-sunny" "yellow")
                  (tile "sensor.sun_next_setting" "Sunset" "mdi:weather-sunset-down" "deep-orange")
                  (tile "sensor.sun_next_dusk" "Dusk" "mdi:weather-night" "indigo")
                ];
              }
              {
                type = "custom:mini-graph-card";
                name = "Precipitation";
                entities = [
                  {
                    entity = "sensor.openweathermap_rain";
                    name = "Rain";
                    color = "#42a5f5";
                  }
                  {
                    entity = "sensor.openweathermap_snow";
                    name = "Snow";
                    color = "#e0e0e0";
                  }
                ];
                hours_to_show = 24;
                group_by = "hour";
                aggregate_func = "max";
                lower_bound = 0;
                font_size = 75;
                show = graphShow // {
                  graph = "bar";
                };
              }
              {
                type = "horizontal-stack";
                cards = [
                  {
                    type = "custom:mini-graph-card";
                    name = "Outdoor Temperature";
                    entities = [
                      {
                        entity = "sensor.openweathermap_temperature";
                        name = "Temperature";
                        color = "#ef5350";
                      }
                      {
                        entity = "sensor.openweathermap_dew_point";
                        name = "Dew Point";
                        color = "#26a69a";
                      }
                    ];
                    hours_to_show = 48;
                    points_per_hour = 1;
                    line_width = 2;
                    font_size = 75;
                    show = graphShow // {
                      extrema = true;
                    };
                  }
                  {
                    type = "custom:mini-graph-card";
                    name = "Pressure";
                    entities = [
                      {
                        entity = "sensor.openweathermap_pressure";
                        color = "#90a4ae";
                      }
                    ];
                    hours_to_show = 48;
                    points_per_hour = 1;
                    line_width = 2;
                    font_size = 75;
                    # keeps small fluctuations from looking like a storm front
                    min_bound_range = 10;
                    show = graphShow // {
                      legend = false;
                    };
                  }
                ];
              }
              {
                type = "horizontal-stack";
                cards = [
                  {
                    type = "custom:mini-graph-card";
                    entities = [
                      {
                        entity = "sensor.temperature_and_humidity_sensor_aqara_living_room_temperature";
                        name = "Living Room";
                        color = "#ef5350";
                      }
                      {
                        entity = "sensor.temperature_and_humidity_sensor_aqara_bed_room_temperature";
                        name = "Bedroom";
                        color = "#42a5f5";
                      }
                      {
                        entity = "sensor.temperature_and_humidity_sensor_aqara_office_temperature";
                        name = "Office";
                        color = "#66bb6a";
                      }
                      {
                        entity = "sensor.openweathermap_temperature";
                        name = "Outdoor";
                        color = outdoorColor;
                      }
                    ];
                    name = "Indoor vs Outdoor Temperature";
                    hours_to_show = 24;
                    points_per_hour = 2;
                    line_width = 2;
                    font_size = 75;
                    animate = true;
                    show = graphShow;
                  }
                  {
                    type = "custom:mini-graph-card";
                    entities = [
                      {
                        entity = "sensor.temperature_and_humidity_sensor_aqara_living_room_humidity";
                        name = "Living Room";
                        color = "#ef5350";
                      }
                      {
                        entity = "sensor.temperature_and_humidity_sensor_aqara_bed_room_humidity";
                        name = "Bedroom";
                        color = "#42a5f5";
                      }
                      {
                        entity = "sensor.temperature_and_humidity_sensor_aqara_office_humidity";
                        name = "Office";
                        color = "#66bb6a";
                      }
                      {
                        entity = "sensor.openweathermap_humidity";
                        name = "Outdoor";
                        color = outdoorColor;
                      }
                    ];
                    name = "Indoor vs Outdoor Humidity";
                    hours_to_show = 24;
                    points_per_hour = 2;
                    line_width = 2;
                    font_size = 75;
                    animate = true;
                    show = graphShow;
                  }
                ];
              }
            ];
        }
      ];
    }
  ];
}

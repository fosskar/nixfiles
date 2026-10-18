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
          cards = [
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
              type = "horizontal-stack";
              cards = [
                {
                  type = "tile";
                  entity = "sensor.openweathermap_temperature";
                  name = "Temperature";
                  icon = "mdi:thermometer";
                  color = "red";
                  tap_action = {
                    action = "none";
                  };
                }
                {
                  type = "tile";
                  entity = "sensor.openweathermap_feels_like_temperature";
                  name = "Feels Like";
                  icon = "mdi:thermometer-lines";
                  color = "orange";
                  tap_action = {
                    action = "none";
                  };
                }
                {
                  type = "tile";
                  entity = "sensor.openweathermap_humidity";
                  name = "Humidity";
                  icon = "mdi:water-percent";
                  color = "blue";
                  tap_action = {
                    action = "none";
                  };
                }
                {
                  type = "tile";
                  entity = "sensor.openweathermap_wind_speed";
                  name = "Wind";
                  icon = "mdi:weather-windy";
                  color = "cyan";
                  tap_action = {
                    action = "none";
                  };
                }
                {
                  type = "tile";
                  entity = "sensor.openweathermap_pressure";
                  name = "Pressure";
                  icon = "mdi:gauge";
                  color = "grey";
                  tap_action = {
                    action = "none";
                  };
                }
                {
                  type = "tile";
                  entity = "sensor.openweathermap_cloud_coverage";
                  name = "Clouds";
                  icon = "mdi:cloud";
                  color = "grey";
                  tap_action = {
                    action = "none";
                  };
                }
              ];
            }
            {
              type = "custom:meteoalarm-card";
              entities = [
                { entity = "sensor.hamburg_nord_current_warning_level"; }
                { entity = "sensor.hamburg_nord_advance_warning_level"; }
              ];
              integration = "dwd";
              disable_swiper = false;
              hide_caption = false;
              override_headline = false;
              hide_when_no_warning = true;
              scaling_mode = "headline_and_scale";
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
                  ];
                  name = "Indoor Temperature";
                  hours_to_show = 24;
                  points_per_hour = 2;
                  line_width = 2;
                  font_size = 75;
                  animate = true;
                  show = {
                    name = true;
                    icon = false;
                    state = true;
                    legend = true;
                    fill = false;
                    labels = true;
                  };
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
                  ];
                  name = "Indoor Humidity";
                  hours_to_show = 24;
                  points_per_hour = 2;
                  line_width = 2;
                  font_size = 75;
                  animate = true;
                  show = {
                    name = true;
                    icon = false;
                    state = true;
                    legend = true;
                    fill = false;
                    labels = true;
                  };
                }
              ];
            }
          ];
        }
      ];
    }
  ];
}

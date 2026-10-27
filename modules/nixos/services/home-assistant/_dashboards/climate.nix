let
  rooms = [
    {
      id = "living_room";
      accent = "#ffb547";
      name = "Living Room";
      icon = "mdi:sofa";
      sensor = "sensor.temperature_and_humidity_sensor_aqara_living_room";
      thermostat = "thermostat_living_room_sonoff";
    }
    {
      id = "bedroom";
      accent = "#9575cd";
      name = "Bedroom";
      icon = "mdi:bed";
      sensor = "sensor.temperature_and_humidity_sensor_aqara_bed_room";
      thermostat = "thermostat_bedroom_sonoff";
    }
    {
      id = "office";
      accent = "#4db6ac";
      name = "Office";
      icon = "mdi:desk";
      sensor = "sensor.temperature_and_humidity_sensor_aqara_office";
      thermostat = "thermostat_office_sonoff";
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

  # on narrow screens the room switcher shows one room at a time; options are the room ids and "house"
  roomSelect = "input_select.climate_room";
  wide = {
    condition = "screen";
    media_query = "(min-width: 768px)";
  };
  shownWhen = option: [
    {
      condition = "or";
      conditions = [
        wide
        {
          condition = "state";
          entity = roomSelect;
          state = option;
        }
      ];
    }
  ];

  bubbleButton = name: icon: hash: {
    type = "custom:bubble-card";
    card_type = "button";
    button_type = "name";
    inherit name icon;
    tap_action = {
      action = "navigate";
      navigation_path = hash;
    };
  };

  popup = hash: name: icon: cards: {
    type = "custom:bubble-card";
    card_type = "pop-up";
    inherit
      hash
      name
      icon
      cards
      ;
    width_desktop = "560px";
    bg_opacity = "55";
    bg_blur = "24";
    backdrop_blur = "6";
  };

  # current temperature large, humidity and heating state beside it
  nowCard = room: {
    type = "custom:button-card";
    entity = "${room.sensor}_temperature";
    show_icon = false;
    show_name = false;
    show_state = false;
    tap_action.action = "more-info";
    grid_options.columns = "full";
    custom_fields = {
      temp = "[[[ const t = parseFloat(states['${room.sensor}_temperature']?.state); return isNaN(t) ? '—' : t.toFixed(1) + '°'; ]]]";
      meta = ''
        [[[
          const h = parseFloat(states['${room.sensor}_humidity']?.state);
          let out = '<div>' + (isNaN(h) ? '—' : Math.round(h) + ' % humidity') + '</div>';
          ${
            if room ? thermostat then
              ''
                const c = states['climate.${room.thermostat}'];
                if (c) {
                  const heating = c.attributes.hvac_action === 'heating';
                  const target = c.state === 'off' ? 'heating off' : 'target ' + c.attributes.temperature + '° · ' + c.state;
                  out += '<div class="' + (heating ? 'on' : "") + '">' + (heating ? 'heating, ' : "") + target + '</div>';
                }
              ''
            else
              ""
          }
          return out;
        ]]]
      '';
    };
    styles.grid = [
      { grid-template-areas = "\"temp meta\""; }
      { grid-template-columns = "auto 1fr"; }
      { column-gap = "20px"; }
      { align-items = "center"; }
    ];
    styles.card = [ { padding = "16px 20px"; } ];
    extra_styles = ''
      #temp { font-size: 44px; font-weight: 300; line-height: 1; justify-self: start; }
      #meta { justify-self: start; text-align: left; font-size: 14px; opacity: 0.8; line-height: 1.6; }
      #meta .on { color: #ffa726; opacity: 1; }
    '';
  };

  roomSection = room: {
    type = "grid";
    background = {
      color = room.accent;
      opacity = 12;
    };
    visibility = shownWhen room.id;
    cards = [
      {
        type = "heading";
        heading = room.name;
        heading_style = "title";
        inherit (room) icon;
        badges = [
          {
            type = "entity";
            entity = "binary_sensor.${room.id}_ventilate";
            icon = "mdi:window-open-variant";
            color = "light-blue";
            show_state = false;
            visibility = [
              {
                condition = "state";
                entity = "binary_sensor.${room.id}_ventilate";
                state = "on";
              }
            ];
          }
        ]
        ++ (
          if room ? thermostat then
            [
              {
                type = "entity";
                entity = "climate.${room.thermostat}";
                state_content = "hvac_action";
                color = "deep-orange";
              }
              {
                type = "entity";
                entity = "sensor.${room.thermostat}_battery";
              }
            ]
          else
            [ ]
        )
        ++ [
          {
            type = "entity";
            entity = "${room.sensor}_battery";
          }
        ];
      }
      (nowCard room)
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
          (bubbleButton "Heating settings" "mdi:calendar-clock" "#${room.id}-heating")
        ]
      else
        [ ]
    )
    ++ [
      (
        graph
        // {
          name = "Last 24 h";
          decimals = 1;
          grid_options.columns = "full";
          entities = [
            {
              entity = "${room.sensor}_temperature";
              name = "Temperature";
              color = "#ffa726";
            }
            {
              entity = "${room.sensor}_humidity";
              name = "Humidity";
              color = "#42a5f5";
              y_axis = "secondary";
            }
          ];
          show = graph.show // {
            legend = true;
          };
        }
      )
      (bubbleButton "History, 14 days" "mdi:chart-line" "#${room.id}-history")
    ];
  };

  roomPopups =
    room:
    (
      if room ? thermostat then
        [
          # same schedule every day; the trv_<room>_weekly_schedule automation writes it to the valve
          (popup "#${room.id}-heating" "${room.name} heating" "mdi:calendar-clock" [
            {
              type = "entities";
              title = "Schedule";
              entities = [
                {
                  entity = "input_datetime.heating_${room.id}_day_start";
                  name = "Day from";
                }
                {
                  entity = "input_datetime.heating_${room.id}_day_end";
                  name = "Day until";
                }
                {
                  entity = "input_number.heating_${room.id}_day_temperature";
                  name = "Day temperature";
                }
                {
                  entity = "input_number.heating_${room.id}_night_temperature";
                  name = "Night temperature";
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
          ])
        ]
      else
        [ ]
    )
    ++ [
      (popup "#${room.id}-history" "${room.name} history" "mdi:chart-line" [
        (daily "Temperature, 14 days" "${room.sensor}_temperature" "#ffa726")
        (daily "Humidity, 14 days" "${room.sensor}_humidity" "#42a5f5")
      ])
    ];

  switcherButton = option: name: icon: {
    type = "custom:button-card";
    entity = roomSelect;
    inherit name icon;
    show_state = false;
    grid_options.columns = 3;
    tap_action = {
      action = "perform-action";
      perform_action = "input_select.select_option";
      target.entity_id = roomSelect;
      data.option = option;
    };
    styles.card = [
      { padding = "8px 4px"; }
      {
        background = "[[[ return entity.state === '${option}' ? 'rgba(255, 255, 255, 0.16)' : 'transparent'; ]]]";
      }
    ];
    styles.name = [ { font-size = "12px"; } ];
    styles.icon = [ { width = "22px"; } ];
  };

  history = heading: icon: card: {
    type = "grid";
    visibility = shownWhen "house";
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
      sections = [
        {
          type = "grid";
          visibility = [
            {
              condition = "screen";
              media_query = "(max-width: 767px)";
            }
          ];
          cards = map (room: switcherButton room.id room.name room.icon) rooms ++ [
            (switcherButton "house" "House" "mdi:home")
          ];
        }
      ]
      ++ map roomSection rooms
      ++ [
        {
          type = "grid";
          visibility = shownWhen "house";
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
        # bubble-card pop-ups stay hidden until their hash is opened
        {
          type = "grid";
          column_span = 3;
          cards = builtins.concatMap roomPopups rooms;
        }
      ];
    }
  ];
}

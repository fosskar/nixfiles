let
  temperatureThresholds = import ./temperature-thresholds.nix;

  rooms = [
    {
      id = "living_room";
      name = "Living Room";
      icon = "mdi:sofa";
      sensor = "sensor.temperature_and_humidity_sensor_aqara_living_room";
      light = "light.living_room_bulbs";
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

  outside = {
    id = "outside";
    name = "Outside";
    icon = "mdi:tree-outline";
    sensor = "sensor.openweathermap";
  };

  # entity -> chip name
  batteries = {
    "sensor.temperature_and_humidity_sensor_aqara_living_room_battery" = "Living Room sensor";
    "sensor.temperature_and_humidity_sensor_aqara_bed_room_battery" = "Bedroom sensor";
    "sensor.temperature_and_humidity_sensor_aqara_office_battery" = "Office sensor";
    "sensor.hue_dimmer_switch_philips_battery" = "Hue dimmer";
  };

  ninaSlots = builtins.genList (n: toString (n + 1)) 5;

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

  amber = "#ffb547";

  # radicale calendars through the caldav integration -> dot color; every home assistant user sees these
  calendars = {
    "calendar.family" = "#b39ddb";
  };

  concat = builtins.concatStringsSep;
  jsList = xs: "[" + concat ", " (map (x: "'${x}'") xs) + "]";
  # button-card styles take a list of single-property maps
  css = attrs: map (name: { ${name} = attrs.${name}; }) (builtins.attrNames attrs);

  navigate = path: {
    action = "navigate";
    navigation_path = path;
  };

  perform = action: target: data: {
    action = "perform-action";
    perform_action = action;
    inherit target data;
  };

  # nested home assistant cards drop their own frame inside a button-card
  frameless = ''
    --ha-card-background: transparent;
    --card-background-color: transparent;
    --ha-card-box-shadow: none;
    --ha-card-border-width: 0px;
    --ha-card-border-color: transparent;
  '';

  # custom fields default to one ellipsised line and a named grid area
  fieldReset = ''
    #container > div { white-space: normal; overflow: visible; text-overflow: clip; }
  '';

  # a button-card that only lays out nested cards, without a frame of its own
  container = layout: cards: {
    type = "custom:button-card";
    show_icon = false;
    show_name = false;
    tap_action.action = "none";
    hold_action.action = "none";
    show_ripple = false;
    grid_options.columns = "full";
    styles.card = css {
      background = "none";
      border = "none";
      box-shadow = "none";
      padding = "0";
      overflow = "visible";
      cursor = "default";
    };
    extra_styles = ''
      #container { ${layout} }
      #container > div { grid-area: auto !important; min-width: 0; }
      /* button-card only sets the hidden attribute, which its own display: block overrides */
      #container > div:has(> button-card[hidden]) { display: none !important; }
    '';
    # numbered keys keep the cards in list order
    custom_fields = builtins.listToAttrs (
      builtins.genList (i: {
        name = "c${toString (10 + i)}";
        value.card = builtins.elemAt cards i;
      }) (builtins.length cards)
    );
  };

  # icon tile, name and a second line; used by the quick actions and the chips
  pill =
    {
      name,
      icon,
      color,
      label ? null,
      action,
      height ? "64px",
      extra ? { },
    }:
    {
      type = "custom:button-card";
      inherit name icon;
      show_label = label != null;
      tap_action = action;
      hold_action.action = "none";
      styles = {
        card = css {
          padding = "0 14px";
          inherit height;
        };
        grid = css (
          {
            grid-template-columns = "40px 1fr";
            column-gap = "12px";
            text-align = "left";
          }
          // (
            if label != null then
              {
                grid-template-areas = ''"i n" "i l"'';
                grid-template-rows = "auto auto";
              }
            else
              {
                grid-template-areas = ''"i n"'';
                grid-template-rows = "auto";
              }
          )
        );
        img_cell = css {
          width = "40px";
          height = "40px";
          border-radius = "12px";
          background = "rgba(255, 255, 255, 0.07)";
        };
        icon = css {
          width = "22px";
          inherit color;
        };
        name = css {
          justify-self = "start";
          align-self = if label != null then "end" else "center";
          font-size = "15px";
          font-weight = "500";
        };
        label = css {
          justify-self = "start";
          align-self = "start";
          font-size = "12px";
          color = "var(--secondary-text-color)";
        };
      };
    }
    // (if label != null then { inherit label; } else { })
    // extra;

  heroText = ''
    [[[
      const st = (e) => states[e] ? states[e].state : undefined;
      const h = new Date().getHours();
      const greet = h < 11 ? 'Good morning' : h < 18 ? 'Good afternoon' : 'Good evening';
      // light.living_room_bulbs groups the living room bulbs, which are counted on their own
      const lit = Object.keys(states).filter((e) => e.startsWith('light.') && e !== 'light.living_room_bulbs' && st(e) === 'on').length;
      const temps = ${
        jsList (map (room: "${room.sensor}_temperature") rooms)
      }.map((e) => parseFloat(st(e))).filter((x) => !isNaN(x));
      const inside = temps.length ? (temps.reduce((a, b) => a + b, 0) / temps.length).toFixed(1) : '?';
      const out = parseFloat(st('sensor.openweathermap_temperature'));
      const cond = helpers.localize(states['weather.forecast_home']).toLowerCase();
      let s = greet + ', ' + user.name + '. ';
      s += lit ? '<b>' + lit + (lit === 1 ? ' light' : ' lights') + '</b> on, ' : 'All lights off, ';
      s += '<b>' + inside + '°</b> inside, ' + (isNaN(out) ? '?' : out.toFixed(1)) + '° and ' + cond + ' outside.';
      if (st('${vacuum}') === 'cleaning') s += ' The Roborock is cleaning.';
      return s;
    ]]]
  '';

  hero = {
    type = "custom:button-card";
    show_icon = false;
    show_name = false;
    tap_action.action = "none";
    hold_action.action = "none";
    show_ripple = false;
    # the clock has no entity to follow, so the card redraws on a timer
    update_timer = 10000;
    grid_options.columns = "full";
    custom_fields = {
      clock = ''
        [[[
          const d = new Date();
          return '<div class="t">' + helpers.formatTime24h(d) + '</div><div class="d">' + helpers.formatDateWeekdayDay(d) + '</div>';
        ]]]
      '';
      text = heroText;
      wx.card = {
        type = "weather-forecast";
        entity = "weather.forecast_home";
        show_current = false;
        show_forecast = true;
        forecast_type = "daily";
        forecast_slots = 5;
      };
    };
    styles.card = css {
      padding = "26px 30px";
      cursor = "default";
      background = "linear-gradient(120deg, rgba(122, 162, 190, 0.22), rgba(122, 162, 190, 0.03) 65%)";
    };
    extra_styles = fieldReset + ''
      #container {
        grid-template-areas: "clock text wx" !important;
        grid-template-columns: auto minmax(0, 1fr) minmax(0, 360px) !important;
        grid-template-rows: auto !important;
        column-gap: 36px;
        row-gap: 18px;
        text-align: left !important;
      }
      #clock .t { font-size: 64px; font-weight: 300; letter-spacing: -2px; line-height: 1; }
      #clock .d { color: var(--secondary-text-color); margin-top: 8px; font-size: 15px; }
      #text { font-size: 19px; font-weight: 300; line-height: 1.5; }
      #text b { font-weight: 500; }
      #wx { ${frameless} }
      @media (max-width: 1000px) {
        #container {
          grid-template-areas: "clock" "text" "wx" !important;
          grid-template-columns: minmax(0, 1fr) !important;
        }
      }
    '';
  };

  # one chip per kind of problem, hidden while there is nothing to say
  chip =
    {
      name,
      icon,
      color,
      hidden,
      action,
    }:
    {
      type = "custom:button-card";
      inherit
        name
        icon
        hidden
        ;
      tap_action = action;
      hold_action.action = "none";
      styles = {
        card = css {
          padding = "8px 16px 8px 10px";
          border-radius = "999px";
          background = "color-mix(in srgb, ${color} 12%, transparent)";
          border = "1px solid color-mix(in srgb, ${color} 45%, transparent)";
          box-shadow = "none";
          width = "auto";
        };
        grid = css {
          grid-template-areas = ''"i n"'';
          grid-template-columns = "22px auto";
          column-gap = "8px";
        };
        icon = css {
          width = "20px";
          inherit color;
        };
        name = css {
          font-size = "14px";
          color = "color-mix(in srgb, ${color} 55%, white)";
        };
      };
    };

  ventilateEntities = map (room: "binary_sensor.${room.id}_ventilate") rooms;
  ninaEntities = map (
    slot: "binary_sensor.nina_warning_hamburg_freie_und_hansestadt_${slot}"
  ) ninaSlots;
  roomNames = "{${
    concat ", " (map (room: "'binary_sensor.${room.id}_ventilate': '${room.name}'") rooms)
  }}";
  batteryNames = "{${
    concat ", " (builtins.attrValues (builtins.mapAttrs (e: n: "'${e}': '${n}'") batteries))
  }}";
  lowBatteries = "Object.entries(${batteryNames}).filter(([e]) => states[e] && parseFloat(states[e].state) < 20)";
  ventilating = "${jsList ventilateEntities}.filter((e) => states[e] && states[e].state === 'on')";
  warnings = "${jsList ninaEntities}.filter((e) => states[e] && states[e].state === 'on')";
  litLights = "Object.keys(states).filter((e) => e.startsWith('light.') && e !== 'light.living_room_bulbs' && states[e].state === 'on')";

  chips =
    container "display: flex !important; flex-wrap: wrap; gap: 10px;" [
      (chip {
        name = "[[[ return 'Let some fresh air in: ' + ${ventilating}.map((e) => (${roomNames})[e]).join(', '); ]]]";
        icon = "mdi:window-open-variant";
        color = "#4fc3f7";
        hidden = "[[[ return ${ventilating}.length === 0; ]]]";
        action = navigate "/dashboard-climate";
      })
      (chip {
        name = "[[[ const l = ${lowBatteries}; return (l.length === 1 ? 'Low battery: ' : l.length + ' low batteries: ') + l.map(([, n]) => n).join(', '); ]]]";
        icon = "mdi:battery-alert-variant-outline";
        color = amber;
        hidden = "[[[ return ${lowBatteries}.length === 0; ]]]";
        action = navigate "/config/devices/dashboard";
      })
      (chip {
        name = "[[[ const n = ${litLights}.length; return n + (n === 1 ? ' light' : ' lights') + ' on · tap to turn off'; ]]]";
        icon = "mdi:lightbulb-group-outline";
        color = amber;
        hidden = "[[[ return ${litLights}.length === 0; ]]]";
        action = perform "light.turn_off" { entity_id = "all"; } { };
      })
      (chip {
        name = "[[[ return ${warnings}.map((e) => states[e.replace('binary_sensor.nina_warning_', 'sensor.').replace(/_(\\d)$/, '_headline_$1')].state).join(' · '); ]]]";
        icon = "mdi:alert-outline";
        color = "#ef5350";
        hidden = "[[[ return ${warnings}.length === 0; ]]]";
        action = navigate "/dashboard-weather";
      })
    ]
    # the chips read entities the card cannot track, so it redraws on a timer
    // {
      update_timer = 5000;
    };

  # chips only show for problems, so the row disappears when nothing is wrong
  chipsVisibility = [
    {
      condition = "or";
      conditions =
        map (entity: {
          condition = "state";
          inherit entity;
          state = "on";
        }) (ventilateEntities ++ ninaEntities)
        ++ map (entity: {
          condition = "numeric_state";
          inherit entity;
          below = 20;
        }) (builtins.attrNames batteries)
        ++ [
          {
            condition = "state";
            entity = "light.living_room_bulbs";
            state = "on";
          }
        ];
    }
  ];

  quick =
    container
      "display: grid !important; grid-template-columns: repeat(auto-fit, minmax(170px, 1fr)) !important; grid-template-areas: none !important; grid-template-rows: auto !important; gap: 12px;"
      [
        (pill {
          name = "Evening";
          label = "warm light, 40 %";
          icon = "mdi:weather-sunset";
          color = amber;
          action = perform "light.turn_on" { area_id = "living_room"; } {
            brightness_pct = 40;
            color_temp_kelvin = 2700;
          };
        })
        (pill {
          name = "Movie";
          label = "dim, 10 %";
          icon = "mdi:movie-open-outline";
          color = "#b39ddb";
          action = perform "light.turn_on" { area_id = "living_room"; } {
            brightness_pct = 10;
            color_temp_kelvin = 2200;
          };
        })
        (pill {
          name = "All off";
          label = "every light";
          icon = "mdi:power";
          color = "#90a4ae";
          action = perform "light.turn_off" { entity_id = "all"; } { };
        })
        (pill {
          name = "Leaving";
          label = "all off + vacuum";
          icon = "mdi:door-open";
          color = "#4fc3f7";
          action = perform "script.turn_on" { entity_id = "script.leaving"; } { } // {
            confirmation.text = "Turn off all lights and start the Roborock?";
          };
        })
        (pill {
          name = "Ask Assist";
          label = "llama_cpp";
          icon = "mdi:microphone-outline";
          color = "#3ddc97";
          action.action = "assist";
        })
      ];

  # rooms with a light or thermostat get inline buttons and a bubble-card pop-up at #<id>
  hasControls = room: room ? light || room ? thermostat;

  roomButtons =
    room:
    container "display: flex !important; flex-wrap: wrap; gap: 8px;" (
      (
        if room ? light then
          [
            (smallButton
              "[[[ return states['${room.light}'] && states['${room.light}'].state === 'on' ? 'Lights on' : 'Lights off'; ]]]"
              "mdi:lightbulb-outline"
              (perform "light.toggle" { entity_id = room.light; } { })
            )
          ]
        else
          [ ]
      )
      ++ (
        if room ? thermostat then
          [
            # the more-info dialog has the setpoint dial
            (smallButton
              "[[[ const c = states['climate.${room.thermostat}']; if (!c) return 'Heating'; return c.state === 'off' ? 'Heating off' : (c.attributes.hvac_action === 'heating' ? 'Heating to ' : 'Target ') + c.attributes.temperature + '°'; ]]]"
              "mdi:radiator"
              {
                action = "more-info";
                entity = "climate.${room.thermostat}";
              }
            )
          ]
        else
          [ ]
      )
    );

  roomPopup = room: {
    type = "custom:bubble-card";
    card_type = "pop-up";
    hash = "#${room.id}";
    inherit (room) name icon;
    width_desktop = "760px";
    bg_opacity = "55";
    bg_blur = "24";
    backdrop_blur = "6";
    # shortcuts only; settings and history live on the climate dashboard
    cards =
      (
        if room ? light then
          [
            {
              type = "tile";
              entity = room.light;
              name = "Lights";
              grid_options.columns = "full";
              features_position = "inline";
              features = [ { type = "light-brightness"; } ];
            }
          ]
        else
          [ ]
      )
      ++ (
        if room ? thermostat then
          [
            {
              type = "tile";
              entity = "climate.${room.thermostat}";
              name = "Heating";
              grid_options.columns = "full";
              features_position = "bottom";
              features = [
                { type = "target-temperature"; }
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
            (
              let
                pause = perform "script.turn_on" { entity_id = "script.pause_heating"; } {
                  variables.thermostat = "climate.${room.thermostat}";
                };
              in
              {
                type = "tile";
                entity = "script.pause_heating";
                name = "Pause heating 5 min";
                hide_state = true;
                tap_action = pause;
                icon_tap_action = pause;
              }
            )
          ]
        else
          [ ]
      )
      ++ [
        {
          type = "custom:bubble-card";
          card_type = "button";
          button_type = "name";
          name = "Climate dashboard";
          icon = "mdi:home-thermometer";
          tap_action = navigate "/dashboard-climate";
        }
      ];
  };

  roomCard =
    room:
    let
      lit = room ? light;
      temperature = "${room.sensor}_temperature";
      humidity = "${room.sensor}_humidity";
      isOn = "states['${room.light}'] && states['${room.light}'].state === 'on'";
    in
    {
      type = "custom:button-card";
      entity = if lit then room.light else temperature;
      inherit (room) name icon;
      tap_action = if hasControls room then navigate "#${room.id}" else navigate "/dashboard-climate";
      hold_action = {
        action = "more-info";
        entity = temperature;
      };
      grid_options.columns = 12;
      custom_fields = {
        tag =
          if room ? sensor && room.id != "outside" then
            "[[[ return states['binary_sensor.${room.id}_ventilate'] && states['binary_sensor.${room.id}_ventilate'].state === 'on' ? '<span>air out</span>' : ''; ]]]"
          else
            "";
        temp = ''
          [[[
            const t = parseFloat(states['${temperature}'] && states['${temperature}'].state);
            const h = parseFloat(states['${humidity}'] && states['${humidity}'].state);
            return '<span class="v">' + (isNaN(t) ? '—' : t.toFixed(1) + '°') + '</span><span class="h">' + (isNaN(h) ? "" : Math.round(h) + ' %') + '</span>';
          ]]]
        '';
        sub =
          if hasControls room then
            { card = roomButtons room; }
          else if room.id == "outside" then
            "[[[ return helpers.localize(states['weather.forecast_home']); ]]]"
          else
            "no lights";
        graph.card = {
          type = "custom:mini-graph-card";
          entities = [ temperature ];
          hours_to_show = 24;
          points_per_hour = 2;
          height = 70;
          line_width = 3;
          animate = true;
          color_thresholds = temperatureThresholds;
          color_thresholds_transition = "hard";
          tap_action.action = "none";
          show = {
            name = false;
            icon = false;
            state = false;
            legend = false;
            labels = false;
            extrema = false;
            fill = "fade";
          };
        };
      };
      styles = {
        card = css (
          {
            padding = "18px 18px 0";
            height = "100%";
          }
          // (
            if lit then
              {
                background = "[[[ return ${isOn} ? 'radial-gradient(280px 170px at 85% 0%, rgba(255, 181, 71, 0.28), transparent 70%)' : 'none'; ]]]";
                border-color = "[[[ return ${isOn} ? 'rgba(255, 181, 71, 0.5)' : ''; ]]]";
              }
            else
              { }
          )
        );
        grid = css {
          grid-template-areas = ''"i n tag" "temp temp temp" "sub sub sub" "graph graph graph"'';
          grid-template-columns = "40px 1fr auto";
          grid-template-rows = "40px auto auto auto";
          column-gap = "12px";
          text-align = "left";
        };
        img_cell = css (
          {
            width = "40px";
            height = "40px";
            border-radius = "50%";
            background = "rgba(255, 255, 255, 0.08)";
            transition = "all 0.3s";
          }
          // (
            if lit then
              {
                background = "[[[ return ${isOn} ? '${amber}' : 'rgba(255, 255, 255, 0.08)'; ]]]";
                box-shadow = "[[[ return ${isOn} ? '0 0 22px rgba(255, 181, 71, 0.55)' : 'none'; ]]]";
              }
            else
              { }
          )
        );
        icon = css {
          width = "22px";
          color =
            if lit then
              "[[[ return ${isOn} ? '#2a1a00' : 'var(--primary-text-color)'; ]]]"
            else
              "var(--primary-text-color)";
        };
        name = css {
          justify-self = "start";
          font-size = "16px";
          font-weight = "500";
        };
      };
      extra_styles = fieldReset + ''
        #tag span { font-size: 12px; padding: 4px 10px; border-radius: 999px; background: rgba(79, 195, 247, 0.16); color: #9fdcf7; }
        #temp { margin-top: 14px; }
        #temp .v { font-size: 30px; font-weight: 300; }
        #temp .h { font-size: 14px; color: var(--secondary-text-color); margin-left: 8px; }
        #sub { color: var(--secondary-text-color); font-size: 13px; margin-top: 2px; }
        #graph { margin: 4px -18px 0; ${frameless} }
      '';
    };

  # header line of the side cards: icon, title, right-aligned status
  sideHead = icon: title: status: ''
    [[[ return '<div class="head"><ha-icon icon="${icon}"></ha-icon><span>${title}</span><span class="r">' + (${status}) + '</span></div>'; ]]]
  '';

  sideStyles = ''
    #container { grid-template-areas: "head" "body" "foot" !important; grid-template-columns: minmax(0, 1fr) !important; grid-template-rows: auto !important; text-align: left !important; justify-items: stretch; row-gap: 8px; }
    .head { display: flex; align-items: center; gap: 8px; color: var(--secondary-text-color); font-size: 13px; }
    .head ha-icon { margin: 0; width: 18px; height: 18px; }
    .head .r { margin-left: auto; font-size: 12px; }
    .big { font-size: 28px; font-weight: 300; }
    .big small { font-size: 14px; color: var(--secondary-text-color); margin-left: 4px; }
    #body { font-size: 14px; }
    #foot { display: flex; gap: 8px; }
  '';

  sideCard =
    attrs:
    {
      type = "custom:button-card";
      show_icon = false;
      show_name = false;
      hold_action.action = "none";
      grid_options.columns = "full";
      styles.card = css { padding = "16px 18px"; };
      extra_styles = fieldReset + sideStyles + (attrs.extraStyles or "");
    }
    // removeAttrs attrs [ "extraStyles" ];

  smallButton = name: icon: action: {
    type = "custom:button-card";
    inherit name icon;
    tap_action = action;
    hold_action.action = "none";
    styles = {
      card = css {
        padding = "6px 14px 6px 10px";
        border-radius = "999px";
        width = "auto";
      };
      grid = css {
        grid-template-areas = ''"i n"'';
        grid-template-columns = "20px auto";
        column-gap = "6px";
      };
      icon = css { width = "18px"; };
      name = css { font-size = "13px"; };
    };
  };

  sum =
    sensors:
    "${jsList sensors}.map((e) => parseFloat(states[e] && states[e].state)).filter((x) => !isNaN(x)).reduce((a, b) => a + b, 0)";

  energy = sideCard {
    # redraw on a timer: the hourly statistics arrive after the first draw
    update_timer = 15000;
    tap_action = navigate "/energy";
    custom_fields = {
      head =
        sideHead "mdi:flash" "Energy today"
          "'yesterday ' + ${sum (map (s: "${s}_yesterday") energySensors)}.toFixed(1) + ' kWh'";
      body = "[[[ return '<div class=\"big\">' + ${
        sum (map (s: "${s}_today") energySensors)
      }.toFixed(2) + '<small>kWh</small></div>'; ]]]";
      foot = ''
        [[[
          const ids = ${jsList (map (s: "${s}_total") energySensors)};
          // hourly statistics are cached for 5 minutes; the next redraw shows them
          const c = window.overviewEnergy || (window.overviewEnergy = { t: 0, data: null });
          if (Date.now() - c.t > 300000) {
            c.t = Date.now();
            const start = new Date();
            start.setHours(0, 0, 0, 0);
            hass.callWS({ type: 'recorder/statistics_during_period', start_time: start.toISOString(), statistic_ids: ids, period: 'hour', types: ['change'] }).then((r) => { c.data = r; });
          }
          const hours = new Array(24).fill(0);
          if (c.data) for (const id of ids) for (const p of (c.data[id] || [])) hours[new Date(p.start).getHours()] += p.change || 0;
          const max = Math.max(...hours, 0.01);
          const now = new Date().getHours();
          let bars = "";
          hours.forEach((v, i) => {
            const height = Math.max(2, v / max * 50);
            bars += '<rect x="' + (i * 10 + 1) + '" y="' + (54 - height) + '" width="8" height="' + height + '" rx="2" fill="' + (i <= now ? '${amber}' : 'rgba(255, 255, 255, 0.1)') + '"/>';
          });
          return '<svg viewBox="0 0 240 54" preserveAspectRatio="none" style="width: 100%; height: 54px; display: block">' + bars + '</svg>';
        ]]]
      '';
    };
    extraStyles = ''
      .head ha-icon { color: ${amber}; }
      #foot { display: block; }
    '';
  };

  agendaCache = "(window.overviewAgenda || (window.overviewAgenda = { t: 0, day: '', events: null, error: null }))";

  agenda = sideCard {
    # redraw on a timer: the events arrive after the first draw
    update_timer = 15000;
    tap_action = navigate "/calendar";
    custom_fields = {
      head =
        sideHead "mdi:calendar-today" "Today"
          "${agendaCache}.events ? ${agendaCache}.events.length + (${agendaCache}.events.length === 1 ? ' event' : ' events') : ''";
      body = ''
        [[[
          const colors = ${builtins.toJSON calendars};
          const c = ${agendaCache};
          const start = new Date();
          start.setHours(0, 0, 0, 0);
          const end = new Date(start);
          end.setDate(end.getDate() + 1);
          // events are cached for 5 minutes and refetched when the day changes
          if (Date.now() - c.t > 300000 || c.day !== start.toDateString()) {
            c.t = Date.now();
            c.day = start.toDateString();
            const q = '?start=' + encodeURIComponent(start.toISOString()) + '&end=' + encodeURIComponent(end.toISOString());
            Promise.all(Object.keys(colors).filter((e) => states[e]).map((e) => hass.callApi('GET', 'calendars/' + e + q).then((r) => r.map((ev) => Object.assign(ev, { cal: e })))))
              .then((l) => { c.events = l.flat().sort((a, b) => (a.start.date ? 0 : 1) - (b.start.date ? 0 : 1) || new Date(a.start.dateTime || a.start.date) - new Date(b.start.dateTime || b.start.date)); c.error = null; })
              .catch((err) => { c.error = (err.body && err.body.message) || err.error || err.message || String(err); });
          }
          if (c.error) return '<div class="none">' + c.error + '</div>';
          if (!c.events) return '<div class="none">Loading…</div>';
          if (!c.events.length) return '<div class="none">Nothing today</div>';
          const esc = (s) => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;');
          const now = new Date();
          return c.events.map((ev) => {
            const allDay = !!ev.start.date;
            const past = !allDay && new Date(ev.end.dateTime) < now;
            const time = allDay ? 'all day' : helpers.formatTime24h(new Date(ev.start.dateTime));
            return '<div class="ev' + (past ? ' past' : "") + '"><i style="background: ' + colors[ev.cal] + '"></i><span class="tm">' + time + '</span><span class="sm">' + esc(ev.summary) + '</span></div>';
          }).join("");
        ]]]
      '';
    };
    extraStyles = ''
      .head ha-icon { color: #4fc3f7; }
      .ev { display: flex; align-items: center; gap: 10px; padding: 3px 0; }
      .ev i { flex: none; width: 8px; height: 8px; border-radius: 50%; }
      .ev .tm { flex: none; width: 52px; color: var(--secondary-text-color); font-size: 13px; }
      .ev .sm { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
      .ev.past { opacity: 0.45; }
      .none { color: var(--secondary-text-color); }
    '';
  };

  roborock = sideCard {
    entity = vacuum;
    tap_action = navigate "/dashboard-roboclean";
    custom_fields = {
      head =
        sideHead "mdi:robot-vacuum" "Roborock"
          "helpers.localize(entity) + ' · ' + Math.round(parseFloat(states['sensor.roborock_qv_35a_battery'].state)) + ' %'";
      body = ''
        [[[
          const area = parseFloat(states['sensor.roborock_qv_35a_cleaning_area'].state);
          const secs = parseFloat(states['sensor.roborock_qv_35a_cleaning_time'].state);
          if (isNaN(area) || isNaN(secs)) return 'No run yet';
          return 'Last run: ' + area.toFixed(1) + ' m² in ' + Math.round(secs / 60) + ' min';
        ]]]
      '';
      foot.card = container "display: flex !important; gap: 8px;" [
        (smallButton "Clean" "mdi:play" (perform "vacuum.start" { entity_id = vacuum; } { }))
        (smallButton "Dock" "mdi:home-import-outline" (
          perform "vacuum.return_to_base" { entity_id = vacuum; } { }
        ))
      ];
    };
  };

  adguard = sideCard {
    entity = "switch.adguard_home_protection";
    tap_action = navigate "/internet-security";
    custom_fields = {
      head =
        sideHead "mdi:shield-check-outline" "AdGuard"
          "entity.state === 'on' ? Math.round(parseFloat(states['sensor.adguard_home_dns_queries_blocked_ratio'].state) * 10) / 10 + ' % blocked' : 'paused'";
      foot.card = container "display: flex !important; gap: 8px;" [
        (smallButton "Pause 10 min" "mdi:timer-pause-outline" (
          perform "script.turn_on" { entity_id = "script.pause_adguard"; } { }
        ))
      ];
    };
  };
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
      sections = [
        {
          type = "grid";
          column_span = 3;
          cards = [ hero ];
        }
        {
          type = "grid";
          column_span = 3;
          visibility = chipsVisibility;
          cards = [ chips ];
        }
        {
          type = "grid";
          column_span = 3;
          cards = [ quick ];
        }
        {
          type = "grid";
          column_span = 2;
          cards = map roomCard (rooms ++ [ outside ]);
        }
        {
          type = "grid";
          cards =
            map (entity: {
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
              agenda
              energy
              roborock
              adguard
            ];
        }
        # bubble-card pop-ups stay hidden until their hash is opened
        {
          type = "grid";
          column_span = 3;
          cards = map roomPopup (builtins.filter hasControls rooms);
        }
      ];
    }
  ];
}

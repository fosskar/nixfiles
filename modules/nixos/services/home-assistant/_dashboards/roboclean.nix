{
  views = [
    {
      type = "sections";
      title = "RoboClean";
      path = "";
      icon = "mdi:robot-vacuum";
      theme = "Frosted Glass Dark Lite";
      sections = [
        {
          type = "grid";
          cards = [
            {
              type = "custom:bubble-card";
              card_type = "button";
              entity = "vacuum.roborock_qv_35a";
              name = "Roborock";
              icon = "mdi:robot-vacuum";
              button_type = "state";
              grid_options = {
                columns = 3;
                rows = 1;
              };
            }
            {
              type = "tile";
              entity = "sensor.roborock_qv_35a_battery";
              name = "Battery";
              icon = "mdi:battery";
              color = "green";
              tap_action = {
                action = "none";
              };
              grid_options = {
                columns = 2;
                rows = 1;
              };
            }
            {
              type = "tile";
              entity = "sensor.roborock_qv_35a_current_room";
              name = "Room";
              icon = "mdi:map-marker";
              color = "cyan";
              tap_action = {
                action = "none";
              };
              grid_options = {
                columns = 2;
                rows = 1;
              };
            }
            {
              type = "custom:bubble-card";
              card_type = "button";
              entity = "switch.roborock_qv_35a_do_not_disturb";
              name = "DND";
              icon = "mdi:moon-waning-crescent";
              button_type = "switch";
              styles = "ha-card { --bubble-accent-color: #ab47bc; }";
              grid_options = {
                columns = 2;
                rows = 1;
              };
            }
            {
              type = "tile";
              entity = "sensor.roborock_qv_35a_vacuum_error";
              name = "Error";
              icon = "mdi:alert-circle-outline";
              color = "green";
              tap_action = {
                action = "none";
              };
              grid_options = {
                columns = 3;
                rows = 1;
              };
            }
            {
              type = "tile";
              entity = "sensor.roborock_qv_35a_main_brush_time_left";
              name = "Main Brush";
              icon = "mdi:brush";
              color = "teal";
              tap_action = {
                action = "more-info";
              };
              grid_options = {
                columns = 3;
                rows = 1;
              };
            }
            {
              type = "tile";
              entity = "sensor.roborock_qv_35a_side_brush_time_left";
              name = "Side Brush";
              icon = "mdi:brush";
              color = "teal";
              tap_action = {
                action = "more-info";
              };
              grid_options = {
                columns = 3;
                rows = 1;
              };
            }
            {
              type = "tile";
              entity = "sensor.roborock_qv_35a_filter_time_left";
              name = "Filter";
              icon = "mdi:air-filter";
              color = "teal";
              tap_action = {
                action = "more-info";
              };
              grid_options = {
                columns = 3;
                rows = 1;
              };
            }
            {
              type = "tile";
              entity = "sensor.roborock_qv_35a_sensor_time_left";
              name = "Sensors";
              icon = "mdi:eye-outline";
              color = "teal";
              tap_action = {
                action = "more-info";
              };
              grid_options = {
                columns = 3;
                rows = 1;
              };
            }
            {
              type = "custom:xiaomi-vacuum-map-card";
              entity = "vacuum.roborock_qv_35a";
              vacuum_platform = "Roborock";
              map_source = {
                camera = "image.roborock_qv_35a_home";
              };
              calibration_source = {
                identity = true;
              };
              map_locked = true;
              two_finger_pan = false;
              icons = [
                {
                  icon = "mdi:play";
                  conditions = [
                    {
                      entity = "vacuum.roborock_qv_35a";
                      value_not = "cleaning";
                    }
                    {
                      entity = "vacuum.roborock_qv_35a";
                      value_not = "error";
                    }
                    {
                      entity = "vacuum.roborock_qv_35a";
                      value_not = "returning";
                    }
                  ];
                  tooltip = "Start";
                  tap_action = {
                    action = "call-service";
                    service = "vacuum.start";
                    service_data = {
                      entity_id = "vacuum.roborock_qv_35a";
                    };
                  };
                }
                {
                  icon = "mdi:pause";
                  conditions = [
                    {
                      entity = "vacuum.roborock_qv_35a";
                      value_not = "docked";
                    }
                    {
                      entity = "vacuum.roborock_qv_35a";
                      value_not = "idle";
                    }
                    {
                      entity = "vacuum.roborock_qv_35a";
                      value_not = "error";
                    }
                    {
                      entity = "vacuum.roborock_qv_35a";
                      value_not = "paused";
                    }
                  ];
                  tooltip = "Pause";
                  tap_action = {
                    action = "call-service";
                    service = "vacuum.pause";
                    service_data = {
                      entity_id = "vacuum.roborock_qv_35a";
                    };
                  };
                }
                {
                  icon = "mdi:stop";
                  conditions = [
                    {
                      entity = "vacuum.roborock_qv_35a";
                      value_not = "docked";
                    }
                    {
                      entity = "vacuum.roborock_qv_35a";
                      value_not = "idle";
                    }
                    {
                      entity = "vacuum.roborock_qv_35a";
                      value_not = "error";
                    }
                    {
                      entity = "vacuum.roborock_qv_35a";
                      value_not = "paused";
                    }
                  ];
                  tooltip = "Stop";
                  tap_action = {
                    action = "call-service";
                    service = "vacuum.stop";
                    service_data = {
                      entity_id = "vacuum.roborock_qv_35a";
                    };
                  };
                }
                {
                  icon = "mdi:home-map-marker";
                  conditions = [
                    {
                      entity = "vacuum.roborock_qv_35a";
                      value_not = "docked";
                    }
                    {
                      entity = "vacuum.roborock_qv_35a";
                      value_not = "returning";
                    }
                  ];
                  tooltip = "Return to base";
                  tap_action = {
                    action = "call-service";
                    service = "vacuum.return_to_base";
                    service_data = {
                      entity_id = "vacuum.roborock_qv_35a";
                    };
                  };
                }
                {
                  icon = "mdi:target-variant";
                  conditions = [
                    {
                      entity = "vacuum.roborock_qv_35a";
                      value_not = "docked";
                    }
                    {
                      entity = "vacuum.roborock_qv_35a";
                      value_not = "error";
                    }
                    {
                      entity = "vacuum.roborock_qv_35a";
                      value_not = "cleaning";
                    }
                    {
                      entity = "vacuum.roborock_qv_35a";
                      value_not = "returning";
                    }
                  ];
                  tooltip = "Clean spot";
                  tap_action = {
                    action = "call-service";
                    service = "vacuum.clean_spot";
                    service_data = {
                      entity_id = "vacuum.roborock_qv_35a";
                    };
                  };
                }
                {
                  icon = "mdi:map-marker";
                  tooltip = "Locate";
                  tap_action = {
                    action = "call-service";
                    service = "vacuum.locate";
                    service_data = {
                      entity_id = "vacuum.roborock_qv_35a";
                    };
                  };
                }
                {
                  menu_id = "fan_speed";
                  icon = "mdi:fan-alert";
                  label = "off";
                  conditions = [
                    {
                      entity = "vacuum.roborock_qv_35a";
                      attribute = "fan_speed";
                      value = "off";
                    }
                  ];
                  tooltip = "Change fan speed";
                  tap_action = {
                    action = "call-service";
                    service = "vacuum.set_fan_speed";
                    service_data = {
                      entity_id = "vacuum.roborock_qv_35a";
                      fan_speed = "off";
                    };
                  };
                }
                {
                  menu_id = "fan_speed";
                  icon = "mdi:fan-alert";
                  label = "quiet";
                  conditions = [
                    {
                      entity = "vacuum.roborock_qv_35a";
                      attribute = "fan_speed";
                      value = "quiet";
                    }
                  ];
                  tooltip = "Change fan speed";
                  tap_action = {
                    action = "call-service";
                    service = "vacuum.set_fan_speed";
                    service_data = {
                      entity_id = "vacuum.roborock_qv_35a";
                      fan_speed = "quiet";
                    };
                  };
                }
                {
                  menu_id = "fan_speed";
                  icon = "mdi:fan-alert";
                  label = "balanced";
                  conditions = [
                    {
                      entity = "vacuum.roborock_qv_35a";
                      attribute = "fan_speed";
                      value = "balanced";
                    }
                  ];
                  tooltip = "Change fan speed";
                  tap_action = {
                    action = "call-service";
                    service = "vacuum.set_fan_speed";
                    service_data = {
                      entity_id = "vacuum.roborock_qv_35a";
                      fan_speed = "balanced";
                    };
                  };
                }
                {
                  menu_id = "fan_speed";
                  icon = "mdi:fan-alert";
                  label = "Turbo";
                  conditions = [
                    {
                      entity = "vacuum.roborock_qv_35a";
                      attribute = "fan_speed";
                      value = "turbo";
                    }
                  ];
                  tooltip = "Change fan speed";
                  tap_action = {
                    action = "call-service";
                    service = "vacuum.set_fan_speed";
                    service_data = {
                      entity_id = "vacuum.roborock_qv_35a";
                      fan_speed = "turbo";
                    };
                  };
                }
                {
                  menu_id = "fan_speed";
                  icon = "mdi:fan-alert";
                  label = "max";
                  conditions = [
                    {
                      entity = "vacuum.roborock_qv_35a";
                      attribute = "fan_speed";
                      value = "max";
                    }
                  ];
                  tooltip = "Change fan speed";
                  tap_action = {
                    action = "call-service";
                    service = "vacuum.set_fan_speed";
                    service_data = {
                      entity_id = "vacuum.roborock_qv_35a";
                      fan_speed = "max";
                    };
                  };
                }
                {
                  menu_id = "fan_speed";
                  icon = "mdi:fan-alert";
                  label = "custom";
                  conditions = [
                    {
                      entity = "vacuum.roborock_qv_35a";
                      attribute = "fan_speed";
                      value = "custom";
                    }
                  ];
                  tooltip = "Change fan speed";
                  tap_action = {
                    action = "call-service";
                    service = "vacuum.set_fan_speed";
                    service_data = {
                      entity_id = "vacuum.roborock_qv_35a";
                      fan_speed = "custom";
                    };
                  };
                }
                {
                  menu_id = "fan_speed";
                  icon = "mdi:fan-alert";
                  label = "max_plus";
                  conditions = [
                    {
                      entity = "vacuum.roborock_qv_35a";
                      attribute = "fan_speed";
                      value = "max_plus";
                    }
                  ];
                  tooltip = "Change fan speed";
                  tap_action = {
                    action = "call-service";
                    service = "vacuum.set_fan_speed";
                    service_data = {
                      entity_id = "vacuum.roborock_qv_35a";
                      fan_speed = "max_plus";
                    };
                  };
                }
                {
                  icon = "mdi:fan-alert";
                  conditions = [
                    {
                      entity = "vacuum.roborock_qv_35a";
                      attribute = "fan_speed";
                      value_not = "off";
                    }
                    {
                      entity = "vacuum.roborock_qv_35a";
                      attribute = "fan_speed";
                      value_not = "quiet";
                    }
                    {
                      entity = "vacuum.roborock_qv_35a";
                      attribute = "fan_speed";
                      value_not = "balanced";
                    }
                    {
                      entity = "vacuum.roborock_qv_35a";
                      attribute = "fan_speed";
                      value_not = "turbo";
                    }
                    {
                      entity = "vacuum.roborock_qv_35a";
                      attribute = "fan_speed";
                      value_not = "max";
                    }
                    {
                      entity = "vacuum.roborock_qv_35a";
                      attribute = "fan_speed";
                      value_not = "custom";
                    }
                    {
                      entity = "vacuum.roborock_qv_35a";
                      attribute = "fan_speed";
                      value_not = "max_plus";
                    }
                  ];
                  tooltip = "Change fan speed";
                  tap_action = {
                    action = "call-service";
                    service = "vacuum.set_fan_speed";
                    service_data = {
                      entity_id = "vacuum.roborock_qv_35a";
                      fan_speed = "off";
                    };
                  };
                }
                {
                  type = "menu";
                  menu_id = "water_box_mode";
                  icon_id = "water_box_mode";
                  available_values_attribute = "options";
                  icon = "mdi:water";
                  icon_mapping = {
                    off = "mdi:water-remove";
                    mild = "mdi:water-minus";
                    moderate = "mdi:water";
                    intense = "mdi:water-plus";
                    custom = "mdi:water-sync";
                  };
                  tap_action = {
                    action = "call-service";
                    service = "select.select_option";
                    service_data = {
                      option = "[[value]]";
                      entity_id = "[[entity_id]]";
                    };
                  };
                  entity = "select.roborock_qv_35a_mop_intensity";
                }
                {
                  type = "menu";
                  menu_id = "mop_mode";
                  icon_id = "mop_mode";
                  available_values_attribute = "options";
                  icon = "mdi:water";
                  icon_mapping = {
                    standard = "mdi:standard-definition";
                    deep = "mdi:high-definition";
                    deep_plus = "mdi:ultra-high-definition";
                    custom = "mdi:fit-to-screen-outline";
                  };
                  tap_action = {
                    action = "call-service";
                    service = "select.select_option";
                    service_data = {
                      option = "[[value]]";
                      entity_id = "[[entity_id]]";
                    };
                  };
                  entity = "select.roborock_qv_35a_mop_mode";
                }
              ];
              tiles = [
                {
                  tile_id = "fan_speed";
                  entity = "vacuum.roborock_qv_35a";
                  label = "Fan speed";
                  attribute = "fan_speed";
                  icon = "mdi:fan";
                  translations = {
                    silent = "Silent";
                    standard = "Standard";
                    medium = "Medium";
                    turbo = "Turbo";
                    auto = "Auto";
                    gentle = "Gentle";
                  };
                }
                {
                  tile_id = "main_brush_left";
                  icon = "mdi:brush";
                  label = "Main brush left";
                  unit = "h";
                  multiplier = 0.0002777777777777778;
                  entity = "sensor.roborock_qv_35a_main_brush_time_left";
                  precision = 0;
                  translations = { };
                }
                {
                  tile_id = "sensor_dirty_left";
                  icon = "mdi:eye-outline";
                  label = "Sensors left";
                  unit = "h";
                  multiplier = 0.0002777777777777778;
                  entity = "sensor.roborock_qv_35a_sensor_time_left";
                  precision = 0;
                  translations = { };
                }
                {
                  tile_id = "filter_left";
                  icon = "mdi:air-filter";
                  label = "Filter left";
                  unit = "h";
                  multiplier = 0.0002777777777777778;
                  entity = "sensor.roborock_qv_35a_filter_time_left";
                  precision = 0;
                  translations = { };
                }
                {
                  tile_id = "side_brush_left";
                  icon = "mdi:brush";
                  label = "Side brush left";
                  unit = "h";
                  multiplier = 0.0002777777777777778;
                  entity = "sensor.roborock_qv_35a_side_brush_time_left";
                  precision = 0;
                  translations = { };
                }
                {
                  tile_id = "cleaning_count";
                  icon = "mdi:counter";
                  label = "Cleaning count";
                  entity = "sensor.roborock_qv_35a_total_cleaning_count";
                  precision = 0;
                  translations = { };
                }
                {
                  tile_id = "cleaned_area";
                  icon = "mdi:texture-box";
                  label = "Cleaned area";
                  unit = "m²";
                  precision = 2;
                  entity = "sensor.roborock_qv_35a_cleaning_area";
                  translations = { };
                }
                {
                  tile_id = "cleaning_time";
                  icon = "mdi:history";
                  label = "Cleaning time";
                  unit = "min";
                  multiplier = 0.016667;
                  entity = "sensor.roborock_qv_35a_cleaning_time";
                  precision = 0;
                  translations = { };
                }
              ];
              map_modes = [
                {
                  name = "Zone cleanup";
                  icon = "mdi:select-drag";
                  run_immediately = false;
                  coordinates_rounding = true;
                  coordinates_to_meters_divider = 1000;
                  selection_type = "MANUAL_RECTANGLE";
                  max_selections = 5;
                  repeats_type = "INTERNAL";
                  max_repeats = 3;
                  service_call_schema = {
                    service = "vacuum.send_command";
                    service_data = {
                      command = "app_zoned_clean";
                      params = "[[selection]]";
                      entity_id = "[[entity_id]]";
                    };
                  };
                  predefined_selections = [ ];
                  variables = { };
                }
                {
                  name = "Pin & Go";
                  icon = "mdi:map-marker-plus";
                  run_immediately = false;
                  coordinates_rounding = true;
                  coordinates_to_meters_divider = 1000;
                  selection_type = "MANUAL_POINT";
                  max_selections = 999;
                  repeats_type = "NONE";
                  max_repeats = 1;
                  service_call_schema = {
                    service = "roborock.set_vacuum_goto_position";
                    service_data = {
                      x = "[[point_x]]";
                      y = "[[point_y]]";
                      entity_id = "[[entity_id]]";
                    };
                  };
                  predefined_selections = [ ];
                  variables = { };
                }
              ];
              additional_presets = [ ];
              grid_options = {
                columns = "full";
                rows = 8;
              };
            }
          ];
          column_span = 2;
        }
      ];
      badges = [ ];
      header = {
        layout = "responsive";
        badges_position = "bottom";
        badges_wrap = "wrap";
      };
      max_columns = 2;
      cards = [ ];
    }
  ];
}

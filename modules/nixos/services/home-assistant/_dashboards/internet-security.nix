{
  views = [
    {
      type = "panel";
      title = "AdGuard Home";
      path = "adguard";
      icon = "mdi:shield-check";
      theme = "Frosted Glass Dark Lite";
      cards = [
        {
          type = "vertical-stack";
          cards = [
            {
              type = "custom:bubble-card";
              card_type = "button";
              entity = "switch.adguard_home_protection";
              name = "AdGuard Protection";
              icon = "mdi:shield-check";
              button_type = "switch";
              styles = "ha-card { --bubble-accent-color: #4caf50; }";
              tap_action = {
                action = "toggle";
                confirmation = {
                  text = "Really toggle AdGuard protection for the whole network?";
                };
              };
            }
            {
              type = "horizontal-stack";
              cards = [
                {
                  type = "tile";
                  entity = "sensor.adguard_home_dns_queries";
                  name = "Queries";
                  icon = "mdi:dns";
                  color = "blue";
                  tap_action = {
                    action = "none";
                  };
                }
                {
                  type = "tile";
                  entity = "sensor.adguard_home_dns_queries_blocked";
                  name = "Blocked";
                  icon = "mdi:shield-off-outline";
                  color = "red";
                  tap_action = {
                    action = "none";
                  };
                }
                {
                  type = "tile";
                  entity = "sensor.adguard_home_dns_queries_blocked_ratio";
                  name = "Block Rate";
                  icon = "mdi:percent";
                  color = "amber";
                  tap_action = {
                    action = "none";
                  };
                }
                {
                  type = "tile";
                  entity = "sensor.adguard_home_average_processing_speed";
                  name = "Avg Speed";
                  icon = "mdi:speedometer";
                  color = "teal";
                  tap_action = {
                    action = "none";
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
                      entity = "sensor.adguard_home_dns_queries_blocked_ratio";
                      name = "Block %";
                      color = "#ef5350";
                    }
                  ];
                  hours_to_show = 168;
                  points_per_hour = 0.5;
                  line_width = 3;
                  font_size = 75;
                  min = 0;
                  max = 100;
                  animate = true;
                  show = {
                    name = true;
                    icon = false;
                    state = true;
                    legend = false;
                    fill = true;
                    labels = true;
                  };
                }
                {
                  type = "custom:mini-graph-card";
                  entities = [
                    {
                      entity = "sensor.adguard_home_average_processing_speed";
                      name = "Speed";
                      color = "#26c6da";
                    }
                  ];
                  hours_to_show = 168;
                  points_per_hour = 0.5;
                  line_width = 3;
                  font_size = 75;
                  animate = true;
                  show = {
                    name = true;
                    icon = false;
                    state = true;
                    legend = false;
                    fill = true;
                    labels = true;
                  };
                }
              ];
            }
            {
              type = "horizontal-stack";
              cards = [
                {
                  type = "custom:bubble-card";
                  card_type = "button";
                  entity = "switch.adguard_home_filtering";
                  name = "Filtering";
                  icon = "mdi:filter";
                  button_type = "switch";
                  styles = "ha-card { --bubble-accent-color: #4caf50; }";
                }
                {
                  type = "custom:bubble-card";
                  card_type = "button";
                  entity = "switch.adguard_home_safe_browsing";
                  name = "Safe Browsing";
                  icon = "mdi:web-check";
                  button_type = "switch";
                  styles = "ha-card { --bubble-accent-color: #26c6da; }";
                }
                {
                  type = "custom:bubble-card";
                  card_type = "button";
                  entity = "switch.adguard_home_parental_control";
                  name = "Parental";
                  icon = "mdi:account-child";
                  button_type = "switch";
                  styles = "ha-card { --bubble-accent-color: #ff9800; }";
                }
                {
                  type = "custom:bubble-card";
                  card_type = "button";
                  entity = "switch.adguard_home_safe_search";
                  name = "Safe Search";
                  icon = "mdi:search-web";
                  button_type = "switch";
                  styles = "ha-card { --bubble-accent-color: #ab47bc; }";
                }
                {
                  type = "custom:bubble-card";
                  card_type = "button";
                  entity = "switch.adguard_home_query_log";
                  name = "Query Log";
                  icon = "mdi:text-box-search-outline";
                  button_type = "switch";
                  styles = "ha-card { --bubble-accent-color: #5c6bc0; }";
                }
              ];
            }
          ];
        }
      ];
    }
  ];
}

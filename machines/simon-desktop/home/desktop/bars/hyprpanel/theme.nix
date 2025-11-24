_:
let
  white = "#eeeeee";
  black = "#171717";
  black2 = "#1e1e1e";
  blackgrey = "#ffffff";
  grey = "#282828";
  lightgrey = "#999999";
  #springgreen = "#33d17a";
  springgreen = "#2BBF6E";
  red = "#ed333b";
  red2 = "#c01c28";
  blue = "#3584e4";
  yellow = "#e5a50a";
  orange = "#ff7800";
  purple = "#9141ac";
in
{

  programs.hyprpanel = {
    settings = {
      theme = {
        notification = {
          background = black;
          actions = {
            background = springgreen;
            text = black;
          };
          label = springgreen;
          border = grey;
          time = white;
          text = white;
          labelicon = springgreen;
          close_button = {
            background = red;
            label = black;
          };
        };
        osd = {
          bar_container = black;
          icon_container = springgreen;
          bar_color = springgreen;
          bar_empty_color = black;
          bar_overflow_color = red;
          icon = black;
          label = white;
        };
        bar = {
          background = black;
          buttons = {
            background = black;
            text = white;
            icon = white;
            dashboard = {
              background = black;
              icon = blue;
            };
            workspaces = {
              background = black;
              border = blackgrey;
              available = white;
              occupied = white;
              active = springgreen;
              hover = springgreen;
              numbered_active_highlighted_text_color = black2;
              numbered_active_underline_color = blackgrey;
            };
            windowtitle = {
              background = black;
              border = black;
              text = white;
              icon = white;
            };
            media = {
              background = black;
              text = white;
              icon = white;
            };
            volume = {
              background = black;
              text = white;
              icon = white;
            };
            network = {
              background = black;
              text = white;
              icon = white;
            };
            bluetooth = {
              background = black;
              text = white;
              icon = blue;
            };
            systray = {
              background = black;
            };
            clock = {
              background = black;
              text = white;
              icon = white;
            };
            notifications = {
              background = black;
              icon = white;
              total = white;
            };
            modules = {
              ram = {
                background = black;
                text = white;
                icon = yellow;
              };
              cpu = {
                background = black;
                text = white;
                icon = orange;
              };
              cpuTemp = {
                background = black;
                text = white;
                icon = red2;
              };
              storage = {
                background = black;
                text = white;
                icon = purple;
              };
              power = {
                background = black;
                icon = red;
              };
              hypridle = {
                background = black;
                icon = yellow;
              };
              microphone = {
                background = black;
                text = white;
                icon = white;
              };
            };
          };
          menus = {
            background = black;
            cards = black2;
            border.color = grey;
            text = white;
            dimtext = lightgrey;
            feinttext = lightgrey;
            label = white;
            popover = {
              text = white;
              background = black2;
            };
            listitems = {
              passive = white;
              active = springgreen;
            };
            icons = {
              passive = white;
              active = springgreen;
            };
            switch = {
              enabled = springgreen;
              disabled = lightgrey;
              puck = black2;
            };
            check_radio_button = {
              background = black;
              active = springgreen;
            };
            buttons = {
              default = springgreen;
              active = springgreen;
              disabled = lightgrey;
              text = black;
            };
            iconbuttons = {
              passive = springgreen;
              active = springgreen;
            };
            progressbar = {
              foreground = springgreen;
              background = black2;
            };
            slider = {
              primary = springgreen;
              background = lightgrey;
              backgroundhover = lightgrey;
              puck = black2;
            };
            dropdownmenu = {
              background = black;
              text = white;
              divider = white;
            };
            tooltip = {
              background = black;
              text = white;
            };
            menu = {
              media = {
                song = white;
                artist = white;
                album = white;
                background.color = black;
                card.color = black2;
                border.color = black2;
                buttons = {
                  inactive = lightgrey;
                  enabled = springgreen;
                  background = springgreen;
                  text = black2;
                };
                slider = {
                  primary = springgreen;
                  background = lightgrey;
                  backgroundhover = black2;
                  puck = black2;
                };
              };
              volume = {
                card.color = black2;
                background.color = black;
                border.color = black2;
                label.color = white;
                text = white;
                listitems = {
                  passive = lightgrey;
                  active = springgreen;
                };
                iconbutton = {
                  passive = lightgrey;
                  active = springgreen;
                };
                icons = {
                  passive = lightgrey;
                  active = springgreen;
                };
                audio_slider = {
                  primary = springgreen;
                  background = lightgrey;
                  backgroundhover = lightgrey;
                  puck = black2;
                };
                input_slider = {
                  primary = springgreen;
                  background = lightgrey;
                  backgroundhover = lightgrey;
                  puck = black2;
                };
              };
              network = {
                card.color = black2;
                background.color = black;
                border.color = black2;
                label.color = white;
                text = white;
                status.color = springgreen;
                listitems = {
                  passive = lightgrey;
                  active = springgreen;
                };
                icons = {
                  passive = lightgrey;
                  active = springgreen;
                };
                iconbuttons = {
                  passive = lightgrey;
                  active = springgreen;
                };
                switch = {
                  enabled = springgreen;
                  disabled = lightgrey;
                  puck = black2;
                };
              };
              bluetooth = {
                card.color = black2;
                background.color = black;
                border.color = black2;
                label.color = blue;
                text = white;
                status = white;
                switch_divider = black;
                switch = {
                  enabled = blue;
                  disabled = lightgrey;
                  puck = black2;
                };
                listitems = {
                  passive = lightgrey;
                  active = blue;
                };
                icons = {
                  passive = lightgrey;
                  active = blue;
                };
                iconbutton = {
                  passive = lightgrey;
                  active = blue;
                };
              };
              systray = {
                dropdownmenu.background = black;
              };
              clock = {
                card.color = black2;
                background.color = black;
                border.color = black2;
                text = white;
                time = {
                  time = white;
                  timeperiod = white;
                };
                calendar = {
                  yearmonth = white;
                  weekdays = springgreen;
                  paginator = white;
                  currentday = springgreen;
                  days = white;
                  contextdays = grey;
                };
                weather = {
                  icon = white;
                  temperature = white;
                  status = white;
                  stats = white;
                  thermometer = {
                    extremelyhot = red;
                    hot = orange;
                    moderate = yellow;
                    cold = blue;
                    extremelycold = purple;
                  };
                  hourly = {
                    time = white;
                    icon = white;
                    temperature = white;
                  };
                };
              };
              dashboard = {
                card.color = black2;
                background.color = black;
                border.color = black2;
                profile.name = white;
                powermenu = {
                  shutdown = red2;
                  restart = orange;
                  logout = springgreen;
                  sleep = blue;
                  confirmation = {
                    card = black2;
                    background = black;
                    border = black2;
                    label = white;
                    body = white;
                    confirm = springgreen;
                    deny = red;
                    button_text = black;
                  };
                };
                shortcuts = {
                  background = springgreen;
                  shortcuts.text = black;
                  recording = red;
                };
                controls = {
                  disabled = lightgrey;
                  wifi = {
                    background = springgreen;
                    text = black;
                  };
                  bluetooth = {
                    background = springgreen;
                    text = black;
                  };
                  notifications = {
                    background = springgreen;
                    text = black;
                  };
                  volume = {
                    background = springgreen;
                    text = black;
                  };
                  input = {
                    background = springgreen;
                    text = black;
                  };
                };
                directories = {
                  left = {
                    top.color = white;
                    middle.color = white;
                    bottom.color = white;
                  };
                  right = {
                    top.color = white;
                    middle.color = white;
                    bottom.color = white;
                  };
                };
                monitors = {
                  bar_background = lightgrey;
                  cpu = {
                    icon = orange;
                    bar = orange;
                    label = orange;
                  };
                  ram = {
                    icon = yellow;
                    bar = yellow;
                    label = yellow;
                  };
                  disk = {
                    icon = purple;
                    bar = purple;
                    label = purple;
                  };
                };
              };
              power = {
                background.color = black;
                border.color = grey;
                buttons = {
                  shutdown = {
                    background = grey;
                    icon_background = red;
                    text = red;
                    icon = black;
                  };
                  restart = {
                    background = grey;
                    icon_background = orange;
                    text = orange;
                    icon = black;
                  };
                  logout = {
                    background = grey;
                    icon_background = springgreen;
                    text = springgreen;
                    icom = black;
                  };
                  sleep = {
                    background = grey;
                    icon_background = blue;
                    text = blue;
                    icon = black;
                  };
                };
              };
              notifications = {
                label = white;
                no_notifications_label = lightgrey;
                background = black;
                card = black2;
                border = black2;
                switch_divider = white;
                clear = springgreen;
                switch = {
                  enabled = springgreen;
                  disabled = lightgrey;
                  puck = black2;
                };
                pager = {
                  background = black;
                  button = springgreen;
                  label = white;
                };
                scrollbar.color = springgreen;
              };
            };
          };
        };
      };
    };
  };
}

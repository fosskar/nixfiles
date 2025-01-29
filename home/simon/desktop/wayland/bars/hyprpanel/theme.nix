_: {

  programs.hyprpanel = {
    override = {
      theme = {
        notification = {
          background = "#171717";
          actions = {
            background = "#33d17a";
            text = "#171717";
          };
          label = "#33d17a";
          border = "#282828";
          time = "#eeeeee";
          text = "#eeeeee";
          labelicon = "#33d17a";
          close_button = {
            background = "#f66151";
            label = "#171717";
          };
        };
        osd = {
          bar_container = "#171717";
          icon_container = "#33d17a";
          bar_color = "#33d17a";
          bar_empty_color = "#171717";
          bar_overflow_color = "#ed333b";
          icon = "#171717";
          label = "#eeeeee";
        };
        bar = {
          background = "#171717";
          buttons = {
            background = "#171717";
            text = "#eeeeee";
            icon = "#eeeeee";
            dashboard = {
              background = "#171717";
              icon = "#62a0ea";
            };
            workspaces = {
              background = "#171717";
              border = "#ffffff";
              available = "#eeeeee";
              occupied = "#eeeeee";
              active = "#33d17a";
              hover = "#33d17a";
              numbered_active_highlighted_text_color = "#1e1e1e";
              numbered_active_underline_color = "#ffffff";
            };
            windowtitle = {
              background = "#171717";
              border = "#171717";
              text = "#eeeeee";
              icon = "#eeeeee";
            };
            media = {
              background = "#171717";
              text = "#eeeeee";
              icon = "#eeeeee";
            };
            volume = {
              background = "#171717";
              text = "#eeeeee";
              icon = "#eeeeee";
            };
            network = {
              background = "#171717";
              text = "#eeeeee";
              icon = "#eeeeee";
            };
            bluetooth = {
              background = "#171717";
              text = "#eeeeee";
              icon = "#3584e4";
            };
            systray = {
              background = "#171717";
            };
            clock = {
              background = "#171717";
              text = "#eeeeee";
              icon = "#eeeeee";
            };
            notifications = {
              background = "#171717";
              icon = "#eeeeee";
              total = "#eeeeee";
            };
            modules = {
              ram = {
                background = "#171717";
                text = "#eeeeee";
                icon = "#f5c211";
              };
              cpu = {
                background = "#171717";
                text = "#eeeeee";
                icon = "#e66100";
              };
              cpuTemp = {
                background = "#171717";
                text = "#eeeeee";
                icon = "#c01c28";
              };
              storage = {
                background = "#171717";
                text = "#eeeeee";
                icon = "#813d9c";
              };
              power = {
                background = "#171717";
                icon = "#ed333b";
              };
              hypridle = {
                background = "#171717";
                icon = "#e5a50a";
              };
            };
          };
          menus = {
            background = "#171717";
            cards = "#1e1e1e";
            border.color = "#272727";
            text = "#eeeeee";
            dimtext = "#c0bfbc";
            feinttext = "#5e5c64";
            label = "#eeeeee";
            popover = {
              text = "#eeeeee";
              background = "#1e1e1e";
            };
            listitems = {
              passive = "#eeeeee";
              active = "#33d17a";
            };
            icons = {
              passive = "#eeeeee";
              active = "#33d17a";
            };
            switch = {
              enabled = "#33d17a";
              disabled = "#5e5c64";
              puck = "#1e1e1e";
            };
            check_radio_button = {
              background = "#171717";
              active = "#33d17a";
            };
            buttons = {
              default = "#33d17a";
              active = "#33d17a";
              disabled = "#77767b";
              text = "#141414";
            };
            iconbuttons = {
              passive = "#33d17a";
              active = "#33d17a";
            };
            progressbar = {
              foreground = "#33d17a";
              background = "#1e1e1e";
            };
            slider = {
              primary = "#33d17a";
              background = "#77767b";
              backgroundhover = "#77767b";
              puck = "#1e1e1e";
            };
            dropdownmenu = {
              background = "#171717";
              text = "#eeeeee";
              divider = "#eeeeee";
            };
            tooltip = {
              background = "#171717";
              text = "#eeeeee";
            };
            menu = {
              media = {
                song = "#eeeeee";
                artist = "#eeeeee";
                album = "#eeeeee";
                background.color = "#171717";
                card.color = "#1e1e1e";
                border.color = "#1e1e1e";
                buttons = {
                  inactive = "#7b7b7b";
                  enabled = "#33d17a";
                  background = "#33d17a";
                  text = "#171717";
                };
                slider = {
                  primary = "#33d17a";
                  background = "#7b7b7b";
                  backgroundhover = "#1e1e1e";
                  puck = "#141414";
                };
              };
              volume = {
                card.color = "#1e1e1e";
                background.color = "#171717";
                border.color = "#1e1e1e";
                label.color = "#eeeeee";
                text = "#eeeeee";
                listitems = {
                  passive = "#999999";
                  active = "#33d17a";
                };
                iconbutton = {
                  passive = "#999999";
                  active = "#33d17a";
                };
                icons = {
                  passive = "#999999";
                  active = "#2ec27e";
                };
                audio_slider = {
                  primary = "#33d17a";
                  background = "#999999";
                  backgroundhover = "#999999";
                  puck = "#4f4f4f";
                };
                input_slider = {
                  primary = "#33d17a";
                  background = "#999999";
                  backgroundhover = "#999999";
                  puck = "#4f4f4f";
                };
              };
              network = {
                card.color = "#1e1e1e";
                background.color = "#171717";
                border.color = "#1e1e1e";
                label.color = "#eeeeee";
                text = "#eeeeee";
                status.color = "#33d17a";
                listitems = {
                  passive = "#565656";
                  active = "#33d17a";
                };
                icons = {
                  passive = "#565656";
                  active = "#33d17a";
                };
                iconbuttons = {
                  passive = "#565656";
                  active = "#33d17a";
                };
                switch = {
                  enabled = "#33d17a";
                  disabled = "#565656";
                  puck = "#171717";
                };
              };
              bluetooth = {
                card.color = "#1e1e1e";
                background.color = "#171717";
                border.color = "#1e1e1e";
                label.color = "#3584e4";
                text = "#eeeeee";
                status = "#eeeeee";
                switch_divider = "#171717";
                switch = {
                  enabled = "#3584e4";
                  disabled = "#555555";
                  puck = "#1e1e1e";
                };
                listitems = {
                  passive = "#999999";
                  active = "#3584e4";
                };
                icons = {
                  passive = "#999999";
                  active = "#3584e4";
                };
                iconbutton = {
                  passive = "#999999";
                  active = "#3584e4";
                };
              };
              systray = {
                dropdownmenu.background = "#171717";
              };
              clock = {
                card.color = "#1e1e1e";
                background.color = "#171717";
                border.color = "#1e1e1e";
                text = "#eeeeee";
                time = {
                  time = "#eeeeee";
                  timeperiod = "#eeeeee";
                };
                calendar = {
                  yearmonth = "#eeeeee";
                  weekdays = "#26a269";
                  paginator = "#eeeeee";
                  currentday = "#33d17a";
                  days = "#eeeeee";
                  contextdays = "#292929";
                };
                weather = {
                  icon = "#eeeeee";
                  temperature = "#eeeeee";
                  status = "#eeeeee";
                  stats = "#eeeeee";
                  thermometer = {
                    extremelyhot = "#e01b24";
                    hot = "#ff7800";
                    moderate = "#f6d32d";
                    cold = "#3584e4";
                    extremelycold = "#9141ac";
                  };
                  hourly = {
                    time = "#eeeeee";
                    icon = "#eeeeee";
                    temperature = "#eeeeee";
                  };
                };
              };
              dashboard = {
                card.color = "#1e1e1e";
                background.color = "#171717";
                border.color = "#1e1e1e";
                profile.name = "#eeeeee";
                powermenu = {
                  shutdown = "#e01b24";
                  restart = "#ff7800";
                  logout = "#33d17a";
                  sleep = "#3584e4";
                  confirmation = {
                    card = "#1e1e1e";
                    background = "#171717";
                    border = "#1e1e1e";
                    label = "#eeeeee";
                    body = "#eeeeee";
                    confirm = "#33d17a";
                    deny = "#ed333b";
                    button_text = "#171717";
                  };
                };
                shortcuts = {
                  background = "#33d17a";
                  shortcuts.text = "#171717";
                  recording = "#ed333b";
                };
                controls = {
                  disabled = "#595959";
                  wifi = {
                    background = "#33d17a";
                    text = "#171717";
                  };
                  bluetooth = {
                    background = "#33d17a";
                    text = "#171717";
                  };
                  notifications = {
                    background = "#33d17a";
                    text = "#171717";
                  };
                  volume = {
                    background = "#33d17a";
                    text = "#171717";
                  };
                  input = {
                    background = "#33d17a";
                    text = "#171717";
                  };
                };
                directories = {
                  left = {
                    top.color = "#eeeeee";
                    middle.color = "#eeeeee";
                    bottom.color = "#eeeeee";
                  };
                  right = {
                    top.color = "#eeeeee";
                    middle.color = "#eeeeee";
                    bottom.color = "#eeeeee";
                  };
                };
                monitors = {
                  bar_background = "#999999";
                  cpu = {
                    icon = "#ff7800";
                    bar = "#ff7800";
                    label = "#ff7800";
                  };
                  ram = {
                    icon = "#f6d32d";
                    bar = "#f6d32d";
                    label = "#f6d32d";
                  };
                  disk = {
                    icon = "#9141ac";
                    bar = "#9141ac";
                    label = "#9141ac";
                  };
                };
              };
              power = {
                background.color = "#171717";
                border.color = "#282828";
                buttons = {
                  shutdown = {
                    background = "#282828";
                    icon_background = "#ed333b";
                    text = "#ed333b";
                    icon = "#171717";
                  };
                  restart = {
                    background = "#292929";
                    icon_background = "#ff7800";
                    text = "#ff7800";
                    icon = "#171717";
                  };
                  logout = {
                    background = "#292929";
                    icon_background = "#33d17a";
                    text = "#33d17a";
                    icom = "#171717";
                  };
                  sleep = {
                    background = "#292929";
                    icon_background = "#62a0ea";
                    text = "#62a0ea";
                    icon = "#171717";
                  };
                };
              };
              notifications = {
                label = "#eeeeee";
                no_notifications_label = "#535353";
                background = "#171717";
                card = "#1e1e1e";
                border = "#1e1e1e";
                switch_divider = "#eeeeee";
                clear = "#33d17a";
                switch = {
                  enabled = "#33d17a";
                  disabled = "#535353";
                  puck = "#1e1e1e";
                };
                pager = {
                  background = "#171717";
                  button = "#33d17a";
                  label = "#eeeeee";
                };
                scrollbar.color = "#33d17a";
              };
            };
          };
        };
      };
    };
  };
}

{
  config,
  lib,
  pkgs,
  ...
}: {
  home.file = {
    ".config/wlogout/icons".source = ./icons;
  };
  programs.wlogout = {
    enable = true;
    layout = [
      {
        label = "lock";
        action = "${pkgs.swaylock-effects}/bin/swaylock -fF";
        text = "Lock";
        keybind = "l";
      }
      {
        label = "hibernate";
        action = "${pkgs.systemd}/bin/systemctl hibernate";
        text = "Hibernate";
        keybind = "h";
      }
      {
        label = "logout";
        action = "${pkgs.systemd}/bin/loginctl terminate-user $USER";
        text = "Logout";
        keybind = "K";
      }
      {
        label = "shutdown";
        action = "${pkgs.systemd}/bin/systemctl poweroff";
        text = "Shutdown";
        keybind = "H";
      }
      {
        label = "suspend";
        action = "${pkgs.systemd}/bin/systemctl suspend-then-hibernate";
        text = "Suspend";
        keybind = "s";
      }
      {
        label = "reboot";
        action = "${pkgs.systemd}/bin/systemctl reboot";
        text = "Reboot";
        keybind = "r";
      }
    ];
    style = ''
      * {
        font-family: "Fira Sans Semibold", FontAwesome, Roboto, Helvetica, Arial, sans-serif;
      	background-image: none;
      }
      window {
      	background-color: rgba(12, 12, 12, 0.9);

      }
      button {
        color: #FFFFFF;
        font-size:20px;
      	background-color: rgba(12, 12, 12, 0.3);
        border: 3px solid #333333;
      	border-style: solid;
      	border-width: 2px;
      	background-repeat: no-repeat;
      	background-position: center;
      	background-size: 25%;
        box-shadow: 0 4px 8px 0 rgba(0, 0, 0, 0.2), 0 6px 20px 0 rgba(0, 0, 0, 0.19);
      }

      button:focus, button:active, button:hover {
        color: #2ec27e;
      	background-color: rgba(12, 12, 12, 0.5);
      	border: 3px solid #2ec27e;
      }

      #lock {
        margin: 10px;
        border-radius: 20px;
        background-image: image(url("${config.home.homeDirectory}/.config/wlogout/icons/lock.png"));
      }

      #logout {
        margin: 10px;
        border-radius: 20px;
        background-image: image(url("${config.home.homeDirectory}/.config/wlogout/icons/logout.png"));
      }

      #suspend {
        margin: 10px;
        border-radius: 20px;
        background-image: image(url("${config.home.homeDirectory}/.config/wlogout/icons/suspend.png"));
      }

      #hibernate {
        margin: 10px;
        border-radius: 20px;
        background-image: image(url("${config.home.homeDirectory}/.config/wlogout/icons/hibernate.png"));
      }

      #shutdown {
        margin: 10px;
        border-radius: 20px;
        background-image: image(url("${config.home.homeDirectory}/.config/wlogout/icons/shutdown.png"));
      }

      #reboot {
        margin: 10px;
        border-radius: 20px;
        background-image: image(url("${config.home.homeDirectory}/.config/wlogout/icons/reboot.png"));
      }
    '';
  };
}

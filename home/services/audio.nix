_: let
  xdg.configHome = let
    x = builtins.getEnv "XDG_CONFIG_HOME";
  in
    if x != ""
    then x
    else "${builtins.getEnv "HOME"}/.config";
in {
  home.file."${xdg.configHome}/wireplumber/wireplumber.conf.d/51-change-channels.conf".text = ''
    monitor.alsa.rules = [
      {
        matches = [
          {
            node.name = "~alsa_output.usb-Focusrite_Scarlett_Solo_USB_Y7NY0CB223AE7B-00.*"
          }
        ]
        actions = {
          update-props = {
            audio.position  = "FR,FL"
          }
        }
      }
    ]
  '';

  home.file."${xdg.configHome}/wireplumber/wireplumber.conf.d/99-low-latency.conf".text = ''
    monitor.alsa.rules = [
      {
        matches = [
          {
            node.name = "~alsa_output.*"
          }
        ]
        actions = {
          update-props = {
            api.alsa.period-size = 256;
          }
        }
      }
    ]
  '';
}

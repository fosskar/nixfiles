{
  home.file.".config/wireplumber/wireplumber.conf.d/51-change-channels.conf".text = ''
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
}

{ self, ... }:
{
  imports = [
    self.modules.nixos.haGreen
    self.modules.nixos.homeAssistant
    self.modules.nixos.mosquitto
    self.modules.nixos.zigbee2mqtt
  ];

  system.etc.overlay.mutable = false;

  # the haGreen module sets the board's consoles; srvos would append ttyS0/ttyAMA0 last
  srvos.boot.consoles = [ ];

  # zigbee network of the former haos install; changing these means re-pairing every device
  services.zigbee2mqtt.settings = {
    serial.port = "/dev/serial/by-id/usb-Nabu_Casa_Home_Assistant_Connect_ZBT-1_34e9ba5d4deced11b4f8071d62c613ac-if00-port0";
    advanced = {
      channel = 25;
      pan_id = 6896;
      ext_pan_id = [
        44
        107
        131
        104
        192
        228
        255
        14
      ];
    };
  };

  system.stateVersion = "26.05";
}

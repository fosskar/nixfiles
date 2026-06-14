{
  flake.modules.homeManager.mpris-proxy = _: {
    # Using Bluetooth headset buttons to control media player
    services.mpris-proxy.enable = true;
  };
}

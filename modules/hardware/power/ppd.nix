{
  flake.modules.nixos.ppd = {
    services.power-profiles-daemon.enable = true;
  };
}

{
  flake.modules.nixos.workstation = _: {
    time.timeZone = "Europe/Berlin";
    services.xserver.xkb.layout = "de";
  };
}

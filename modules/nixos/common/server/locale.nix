{
  flake.modules.nixos.server = _: {
    time.timeZone = "UTC";
  };
}

{
  flake.modules.nixos.workstation = _: {
    security.sudo-rs.wheelNeedsPassword = false;
  };
}

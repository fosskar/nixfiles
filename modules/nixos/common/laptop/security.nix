{
  flake.modules.nixos.laptop = {
    security.forcePageTableIsolation = true;
  };
}

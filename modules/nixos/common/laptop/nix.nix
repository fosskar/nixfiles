{
  flake.modules.nixos.laptop = {
    systemd.services.nix-gc.unitConfig.ConditionACPower = true;
  };
}

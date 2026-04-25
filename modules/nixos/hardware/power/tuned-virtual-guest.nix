{ config, lib, ... }:
{
  flake.modules.nixos.tunedVirtualGuest = {
    imports = [ config.flake.modules.nixos.tuned ];

    services.tuned.recommend = lib.mkForce {
      virtual-guest = { };
    };

    systemd.services.tuned.restartTriggers = lib.mkForce [ "virtual-guest" ];
  };
}

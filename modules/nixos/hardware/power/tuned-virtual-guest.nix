{ config, ... }:
{
  flake.modules.nixos.tunedVirtualGuest = {
    imports = [ config.flake.modules.nixos.tuned ];

    services.tuned.recommend.virtual-guest = { };

    systemd.services = {
      tuned.restartTriggers = [ "virtual-guest" ];
      # unit ships with the tuned package even when ppdSupport=false
      tuned-ppd.enable = false;
    };
  };
}

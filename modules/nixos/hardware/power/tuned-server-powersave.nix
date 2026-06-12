{ config, ... }:
{
  flake.modules.nixos.tunedServerPowersave = {
    imports = [ config.flake.modules.nixos.tuned ];

    services.tuned.recommend.server-powersave = { };

    systemd.services = {
      tuned.restartTriggers = [ "server-powersave" ];
      # unit ships with the tuned package even when ppdSupport=false
      tuned-ppd.enable = false;
    };
  };
}

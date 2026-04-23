{ config, lib, ... }:
{
  flake.modules.nixos.tunedServerPowersave = {
    imports = [ config.flake.modules.nixos.tuned ];

    services.tuned.recommend = lib.mkForce {
      server-powersave = { };
    };

    systemd.services.tuned.restartTriggers = lib.mkForce [ "server-powersave" ];
  };
}

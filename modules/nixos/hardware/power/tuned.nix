{
  flake.modules.nixos.tuned =
    { lib, config, ... }:
    {
      services.tuned = {
        enable = true;
        ppdSupport = lib.mkDefault false;
        recommend = lib.mkIf (!(config.services.tuned.ppdSupport or false)) {
          balanced = lib.mkDefault { };
        };
      };

      systemd.services.tuned.restartTriggers = [ "balanced" ];

      services.tlp.enable = lib.mkForce false;
    };
}

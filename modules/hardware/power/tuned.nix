{
  flake.modules.nixos.tuned =
    { lib, config, ... }:
    {
      options.nixfiles.tuned.profile = lib.mkOption {
        type = lib.types.str;
        default = "balanced";
        description = "tuned profile";
      };

      config =
        let
          cfg = config.nixfiles.tuned;
        in
        {
          services.tuned = {
            enable = true;
            ppdSupport = lib.mkDefault false;
            recommend = lib.mkIf (!(config.services.tuned.ppdSupport or false)) {
              ${cfg.profile} = { };
            };
          };

          systemd.services.tuned.restartTriggers = [ cfg.profile ];

          services.tlp.enable = lib.mkForce false;
        };
    };
}

{
  lib,
  config,
  ...
}:
let
  cfg = config.nixfiles.power.tuned;
in
{
  config = lib.mkIf cfg.enable {
    services.tuned = {
      enable = true;
      ppdSupport = lib.mkForce cfg.ppdSupport;
      settings.dynamic_tuning = cfg.ppdSupport;
      # profiles: map PPD API names to tuned profiles
      # battery: override tuned profile when on battery (key = PPD profile name)
      # when ppdSupport=false, use recommend to set the default profile
      recommend = lib.mkIf (!cfg.ppdSupport) {
        ${cfg.profile} = { };
      };
      ppdSettings = lib.mkIf cfg.ppdSupport {
        battery = {
          # when on battery + PPD "balanced" selected -> use batteryProfile
          balanced = cfg.batteryProfile;
        };
      };
    };

    # restart tuned when profile changes
    systemd.services.tuned.restartTriggers = [
      cfg.profile
      cfg.ppdSupport
    ];

    # tuned conflicts with tlp
    services.tlp.enable = lib.mkForce false;
  };
}

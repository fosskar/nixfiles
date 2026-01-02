{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.nixfiles.power.tuned;
  ppdSettingsFormat = pkgs.formats.ini { };
in
{
  config = lib.mkIf cfg.enable {
    services.tuned = {
      enable = true;
      ppdSupport = lib.mkForce cfg.ppdSupport;
      settings.dynamic_tuning = cfg.ppdSupport;
      # profiles: map PPD API names to tuned profiles
      # battery: override tuned profile when on battery (key = PPD profile name)
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

    environment.etc = lib.mkMerge [
      # workaround: upstream bug - ppd.conf entry exists but source undefined when ppdSupport=false
      # TODO: remove after nixpkgs#463443 is merged
      (lib.mkIf (!cfg.ppdSupport) {
        "tuned/ppd.conf".source = ppdSettingsFormat.generate "ppd.conf" { };
        "tuned/active_profile".text = cfg.profile;
        "tuned/profile_mode".text = "manual";
      })
    ];
  };
}

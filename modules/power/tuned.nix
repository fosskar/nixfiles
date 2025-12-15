{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.nixfiles.power.tuned;
  profiles = if builtins.isList cfg.profile then cfg.profile else [ cfg.profile ];
  profileString = lib.concatStringsSep " " profiles;
  isMultiProfile = builtins.length profiles > 1;
in
{
  config = lib.mkIf cfg.enable {
    services.tuned.enable = true;

    # single profile: use etc file
    environment.etc = lib.mkIf (!isMultiProfile) {
      "tuned/active_profile".text = profileString;
      "tuned/profile_mode".text = "manual";
    };

    # multi profile: use tuned-adm after tuned starts
    systemd.services.tuned-set-profile = lib.mkIf isMultiProfile {
      description = "Set tuned profile";
      after = [ "tuned.service" ];
      requires = [ "tuned.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";
        ExecStart = "${pkgs.tuned}/bin/tuned-adm profile ${profileString}";
        RemainAfterExit = true;
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };
  };
}

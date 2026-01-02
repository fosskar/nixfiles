{
  lib,
  config,
  ...
}:
let
  cfg = config.nixfiles.power.logind;
in
{
  config = lib.mkIf cfg.enable {
    services.logind.settings.Login = {
      HandleLidSwitch = "suspend";
      HandleLidSwitchDocked = "ignore";
      HandleLidSwitchExternalPower = "suspend";
      HandlePowerKey = "suspend";
      HandlePowerKeyLongPress = "poweroff";
    };
  };
}

{
  flake.modules.nixos.logind = {
    services.logind.settings.Login = {
      HandleLidSwitch = "suspend";
      HandleLidSwitchDocked = "ignore";
      HandleLidSwitchExternalPower = "suspend";
      HandlePowerKey = "suspend";
      HandlePowerKeyLongPress = "poweroff";
    };
  };
}

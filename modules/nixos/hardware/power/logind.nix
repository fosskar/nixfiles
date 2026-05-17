{
  flake.modules.nixos.logind = {
    services.logind.settings.Login = {
      HandleHibernateKey = "suspend";
      HandleLidSwitch = "suspend";
      HandleLidSwitchDocked = "ignore";
      HandleLidSwitchExternalPower = "suspend";
      HandlePowerKey = "suspend";
      HandlePowerKeyLongPress = "poweroff";
    };
  };
}

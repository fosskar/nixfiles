{ lib, ... }:
{
  environment.stub-ld.enable = lib.mkDefault false;

  systemd = {
    enableEmergencyMode = false;
    targets = {
      sleep.enable = false;
      suspend.enable = false;
      hibernate.enable = false;
      hybrid-sleep.enable = false;
    };
    settings.Manager = {
      RuntimeWatchdogSec = lib.mkDefault "15s";
      RebootWatchdogSec = lib.mkDefault "30s";
      KExecWatchdogSec = lib.mkDefault "1m";
    };
  };

  environment.variables.BROWSER = "echo";
  fonts.fontconfig.enable = lib.mkDefault false;

  xdg = {
    autostart.enable = lib.mkDefault false;
    icons.enable = lib.mkDefault false;
    menus.enable = lib.mkDefault false;
    mime.enable = lib.mkDefault false;
    sounds.enable = lib.mkDefault false;
  };
}

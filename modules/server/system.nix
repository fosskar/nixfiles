{ lib, ... }:
{
  environment.stub-ld.enable = lib.mkDefault false;

  systemd = {
    enableEmergencyMode = false;
    sleep.extraConfig = ''
      AllowSuspend=no
      AllowHibernation=no
    '';
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

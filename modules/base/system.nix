{ lib, ... }:
{
  disabledModules = [
    "profiles/all-hardware.nix"
    "profiles/base.nix"
  ];

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
  services.journald.extraConfig = ''
    SystemMaxUse=100M
    RuntimeMaxUse=50M
  '';

  environment = {
    variables = {
      BROWSER = "echo";
      EDITOR = "nvim --clean";
    };
    ldso32 = null;
  };

  fonts.fontconfig.enable = lib.mkDefault false;
}

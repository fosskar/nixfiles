{ lib, ... }:
{
  disabledModules = [
    "profiles/all-hardware.nix"
    "profiles/base.nix"
  ];

  systemd = {
    enableEmergencyMode = false;
    watchdog = {
      runtimeTime = "15s";
      rebootTime = "30s";
      kexecTime = "1m";
    };
    sleep.extraConfig = ''
      AllowSuspend=no
      AllowHibernation=no
    '';
    # Don't start a tty on the serial consoles.
    services = {
      "serial-getty@ttyS0".enable = lib.mkDefault false;
      "serial-getty@hvc0".enable = false;
      "getty@tty1".enable = false;
      "autovt@".enable = false;
    };
  };
  services.journald.extraConfig = ''
    SystemMaxUse=100M
    RuntimeMaxUse=50M
  '';

  environment = {
    variables = {
      BROWSER = "echo";
      EDITOR = "neovim";
    };
    stub-ld.enable = lib.mkDefault false;
    ldso32 = null;
  };

  fonts.fontconfig.enable = lib.mkDefault false;
}

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
    stub-ld.enable = lib.mkDefault false;
    ldso32 = null;
  };

  fonts.fontconfig.enable = lib.mkDefault false;
}

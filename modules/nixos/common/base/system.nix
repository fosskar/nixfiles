{
  flake.modules.nixos.base =
    { lib, ... }:
    {
      disabledModules = [
        "profiles/all-hardware.nix"
        "profiles/base.nix"
      ];

      system.tools.nixos-generate-config.enable = false;

      # shellcheck all unit scripts at build time
      systemd.enableStrictShellChecks = lib.mkDefault true;

      services.journald.extraConfig = ''
        SystemMaxUse=500M
        SystemKeepFree=1G
        SystemMaxFileSize=50M
        MaxRetentionSec=1week
      '';

      environment = {
        variables.EDITOR = lib.mkForce "nvim --clean";
        ldso32 = null;
      };
    };
}

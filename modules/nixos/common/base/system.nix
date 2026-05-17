{
  flake.modules.nixos.base =
    { lib, ... }:
    {
      disabledModules = [
        "profiles/all-hardware.nix"
        "profiles/base.nix"
      ];

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

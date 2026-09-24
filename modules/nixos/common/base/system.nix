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

      environment = {
        variables.EDITOR = lib.mkForce "nvim --clean";
        ldso32 = null;
      };
    };
}

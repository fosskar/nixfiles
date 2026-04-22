{
  flake.modules.nixos.workstation =
    { pkgs, ... }:
    {
      services.printing.enable = true;
      environment.systemPackages = [ pkgs.system-config-printer ];
    };
}

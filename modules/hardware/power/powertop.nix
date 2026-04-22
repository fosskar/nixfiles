{
  flake.modules.nixos.powertop =
    { pkgs, ... }:
    {
      powerManagement.powertop.enable = true;
      environment.systemPackages = [ pkgs.powertop ];
    };
}

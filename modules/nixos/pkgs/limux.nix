{
  flake.modules.nixos.limux =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.custom.limux ];
    };
}

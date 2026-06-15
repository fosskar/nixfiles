{
  flake.modules.nixos.limux =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.local.limux ];
    };
}

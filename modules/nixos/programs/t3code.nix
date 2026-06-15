{
  flake.modules.nixos.t3code =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.local.t3code ];
    };
}

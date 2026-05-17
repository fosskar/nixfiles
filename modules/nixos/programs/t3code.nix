{
  flake.modules.nixos.t3code =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.custom.t3code ];
    };
}

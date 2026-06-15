{
  flake.modules.nixos.arbor =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.local.arbor ];
      fonts.packages = [ pkgs.nerd-fonts.caskaydia-mono ];
    };
}

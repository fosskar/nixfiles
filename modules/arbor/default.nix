{
  pkgs,
  ...
}:
{
  environment.systemPackages = [ pkgs.custom.arbor ];
  fonts.packages = [ pkgs.nerd-fonts.caskaydia-mono ];
}

{
  pkgs,
  ...
}:
{
  environment.systemPackages = [ pkgs.custom.t3code ];
}

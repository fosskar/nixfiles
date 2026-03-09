{
  pkgs,
  ...
}:
{
  environment.systemPackages = [ pkgs.custom.agent-desktop ];
}

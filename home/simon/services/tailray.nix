{ inputs, ... }:
{
  imports = [ inputs.tailray.homeManagerModules.default ];

  # tailscale systray
  services.tailray.enable = true;
}
